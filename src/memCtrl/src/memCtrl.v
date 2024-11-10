// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef MEMCTRL_H
`define MEMCTRL_H


/* 8-Bit Memory controller interface using LY68S3200 
   32M (4Mx8) Bits Serial Pseudo-SRAM with SPI and QPI.
   Single bytes are written 4x, so error correction would be possible 
   by comparing the four bytes for equality (and taking the highest occuring value)
   when in doubt, but this is not (yet) implemented. */


typedef enum bit[6:0] {
  stateReset=0,
  stateInit_1=1,
  stateInit_2=2,
  stateEnableQPI=3,
  stateIdle=4,
  stateWrite_Cmd=5,
  stateWrite_Addr_1=6,
  stateWrite_Addr_2=7,
  stateWrite_Addr_3=8,
  stateWrite_Addr_4=9,
  stateWrite_Addr_5=10,
  stateWrite_Addr_6=11,

  stateWrite_SendWriteCmd_1=12,
  stateWrite_SendWriteCmd_2=13,
  stateWrite_SendWriteCmd_3=14,
  stateWrite_SendWriteCmd_4=15,
  stateWrite_SendWriteCmd_5=16,
  stateWrite_SendWriteCmd_6=17,
  stateWrite_SendWriteCmd_7=18,

  stateWrite_SendAddr23_20=19,
  stateWrite_SendAddr19_16=20,
  stateWrite_SendAddr15_12=21,
  stateWrite_SendAddr11_8=22,
  stateWrite_SendAddr7_4=23,
  stateWrite_SendAddr3_0=24,

  stateWrite_SendData7_4=25,
  stateWrite_SendData3_0=26,

  stateRead_SendReadCmd_1=27,
  stateRead_SendReadCmd_2=28,
  stateRead_SendReadCmd_3=29,
  stateRead_SendReadCmd_4=30,
  stateRead_SendReadCmd_5=31,
  stateRead_SendReadCmd_6=32,
  stateRead_SendReadCmd_7=33,

  stateRead_SendAddr23_20=34,
  stateRead_SendAddr19_16=35,
  stateRead_SendAddr15_12=36,
  stateRead_SendAddr11_8=37,
  stateRead_SendAddr7_4=38,
  stateRead_SendAddr3_0=39,

  stateRead_WaitCycle_1=40,
  stateRead_WaitCycle_2=41,
  stateRead_WaitCycle_3=42,
  stateRead_WaitCycle_4=43,
  stateRead_WaitCycle_5=44,
  stateRead_WaitCycle_6=45,
  stateRead_WaitCycle_7=46,

  stateRead7_4=47,
  stateRead3_0=48

 
} StateMachine;

typedef enum bit[7:0] {
  enableQPIMode=8'h35,
  SPIQuadWrite=8'h38,
  SPIQuadRead=8'heb
} QPICommands;

typedef enum reg  {
  READ=0,
  WRITE=1
} Direction;

module memCtrl( input wire clkPhi0, // CPU clock (~1 Mhz)
                input wire clkRAM,  // RAM clock (100Mhz)
                input wire reset,
                input wire CS,    // 1-enable
                input wire write, // 0-read, 1-write
                input wire [5:0]  bank,  // bank 0-31, each of 64KB = 2097152 bytes
                input wire [15:0] addrBus,
                output wire o_psram_sclk,                
                input wire [7:0] dataToWrite,
                output wire [7:0] dataRead,
                inout wire io_psram_data0,
                inout wire io_psram_data1,
                inout wire io_psram_data2,
                inout wire io_psram_data3,
                inout wire io_psram_data4,                
                inout wire io_psram_data5,
                inout wire io_psram_data6,
                inout wire io_psram_data7,            
                output wire o_psram_cs,
                output wire o_busy, // 1-busy
                output wire o_dataReady); 
  
  reg [3:0] dataU7;
  reg [3:0] dataBufferU7;
  
  reg [3:0] dataU9;
  reg [3:0] dataBufferU9;

  reg isWrite;
  reg [7:0] qpiCommand;

//  assign  dataRead[0]=dataReady ? byteToRead[0] : 1'bZ;
//  assign  dataRead[1]=dataReady ? byteToRead[1] : 1'bZ; 
//  assign  dataRead[2]=dataReady ? byteToRead[2] : 1'bZ; 
//  assign  dataRead[3]=dataReady ? byteToRead[3] : 1'bZ; 
//  assign  dataRead[4]=dataReady ? byteToRead[4] : 1'bZ; 
//  assign  dataRead[5]=dataReady ? byteToRead[5] : 1'bZ; 
//  assign  dataRead[6]=dataReady ? byteToRead[6] : 1'bZ; 
//  assign  dataRead[7]=dataReady ? byteToRead[7] : 1'bZ; 


  reg dataReady;        
  assign o_dataReady=dataReady;

  reg [24:0] address;
  reg [24:0] addressBuffer;


  // Loops through 3-0 to reuse write state, writing 4x same byte
  reg [3:0] byteToSendCounter;

  parameter LOW=1'b0;
  parameter HIGH=1'b1;
 
  parameter initDelayInClkCyles=7500; // 150us @100Mhz/2
  integer delayCounter;
  
  StateMachine state=stateRead_SendAddr3_0, nextState;
    
  reg [7:0] qpiCmd;

  reg [7:0] byteToWrite;
  reg [7:0] byteToWriteBuffer;
  reg [7:0] byteToReadBuffer;
  reg [7:0] byteToRead;

  reg isBusy;
  assign o_busy=isBusy;
  
  reg fetchData;

  reg psram_cs;
  assign o_psram_cs= psram_cs;
  
  shortint shifter;
 
  reg psram_sclk;
  assign o_psram_sclk=clkRAM;

  // Direction direction; // 0- in (read), 1-out (write)
  reg [7:0] direction;

  assign io_psram_data0=(direction[0]==1 ? dataU7[0] : 1'bZ);
  assign io_psram_data1=(direction[1]==1 ? dataU7[1] : 1'bZ);
  assign io_psram_data2=(direction[2]==1 ? dataU7[2] : 1'bZ);
  assign io_psram_data3=(direction[3]==1 ? dataU7[3] : 1'bZ);

  assign io_psram_data4=(direction[4]==1 ? dataU9[0] : 1'bZ);
  assign io_psram_data5=(direction[5]==1 ? dataU9[1] : 1'bZ);
  assign io_psram_data6=(direction[6]==1 ? dataU9[2] : 1'bZ);
  assign io_psram_data7=(direction[7]==1 ? dataU9[3] : 1'bZ);

  always @(posedge clkRAM or posedge reset) begin
    if (reset) begin
      state<=stateReset;
    end    
    else state<=nextState;
  end

  always @(negedge clkRAM) begin

  end

  always @(posedge clkPhi0) begin
    fetchData=0;
    if (CS) begin
      if (state==stateIdle) begin          
        fetchData=1;
        byteToWriteBuffer=dataToWrite;
        addressBuffer=addrBus<<3;  
        addressBuffer[23]=bank[4];  
        addressBuffer[22]=bank[3];
        addressBuffer[21]=bank[2];
        addressBuffer[20]=bank[1];
        addressBuffer[19]=bank[0];  
        isWrite=write;
      end
    end
  end

  always @(posedge clkRAM) begin
    case (state)
      stateReset: begin
        delayCounter=initDelayInClkCyles;
        nextState=stateInit_1;
        psram_cs=HIGH;
        isBusy=1;
        shifter=0;
      end

      stateInit_1: begin
        if (delayCounter>0) delayCounter--;
        else nextState=stateInit_2;
      end

      stateInit_2: begin // Enable QPI mode
        shifter=7;
        direction[0]=1;
        direction[1]=0;
        direction[2]=0;
        direction[3]=0;
        direction[4]=1;
        direction[5]=0;
        direction[6]=0;
        direction[7]=0;
        nextState=stateEnableQPI;
      end

      stateEnableQPI: begin // Enable QPI mode
        psram_cs=LOW;
        qpiCommand=enableQPIMode;
        if (shifter>=0) begin
          dataU7[0]=qpiCommand[shifter];    
          dataU9[0]=qpiCommand[shifter];
          shifter--;
        end        
        else nextState=stateIdle;
      end

      stateIdle: begin        
        isBusy=0;
        if (fetchData) begin
          isBusy=1;
          dataU7[1]=1'bZ;
          dataU7[2]=1'bZ;
          dataU7[3]=1'bZ;
          byteToWrite=byteToWriteBuffer;
          address=addressBuffer;  
          address[23]=addressBuffer[23];
          address[22]=addressBuffer[22];
          address[21]=addressBuffer[21];
          address[20]=addressBuffer[20];
          address[19]=addressBuffer[19];
          dataU7[0]=dataBufferU7[0];
          direction=WRITE;
          psram_cs=LOW;
          if (isWrite) begin
            nextState=stateWrite_SendWriteCmd_1;
            dataBufferU7[0]=SPIQuadWrite[7];
          end
          else begin
            nextState=stateRead_SendReadCmd_1;
            dataBufferU7[0]=SPIQuadRead[7];
          end
        end
      end 

      default: begin
        if (state>=stateRead_SendReadCmd_1 && state<=stateRead_SendReadCmd_7) begin
          case (state)
            stateRead_SendReadCmd_1: dataU7[0]=SPIQuadRead[6];
            stateRead_SendReadCmd_2: dataU7[0]=SPIQuadRead[5];
            stateRead_SendReadCmd_3: dataU7[0]=SPIQuadRead[4];
            stateRead_SendReadCmd_4: dataU7[0]=SPIQuadRead[3];
            stateRead_SendReadCmd_5: dataU7[0]=SPIQuadRead[2];
            stateRead_SendReadCmd_6: dataU7[0]=SPIQuadRead[1];
            stateRead_SendReadCmd_7: dataU7[0]=SPIQuadRead[0];
          endcase
          nextState++;
        end 
        else if (state>=stateRead_SendAddr23_20 && state<=stateRead_SendAddr3_0) begin
          case (state)
            stateRead_SendAddr23_20: begin
              dataU7[0]=address[20];
              dataU7[1]=address[21];
              dataU7[2]=address[22];
              dataU7[3]=address[23];
            end

            stateRead_SendAddr19_16: begin
              dataU7[0]=address[16];
              dataU7[1]=address[17];
              dataU7[2]=address[18];
              dataU7[3]=address[19];
            end

            stateRead_SendAddr15_12: begin
              dataU7[0]=address[12];
              dataU7[1]=address[13];
              dataU7[2]=address[14];
              dataU7[3]=address[15];
            end

            stateRead_SendAddr11_8: begin
              dataU7[0]=address[8];
              dataU7[1]=address[9];
              dataU7[2]=address[10];
              dataU7[3]=address[11];
            end

            stateRead_SendAddr7_4: begin
              dataU7[0]=address[4];
              dataU7[1]=address[5];
              dataU7[2]=address[6];
              dataU7[3]=address[7];
            end

            stateRead_SendAddr3_0: begin
              dataU7[0]=address[0];
              dataU7[1]=address[1];
              dataU7[2]=address[2];
              dataU7[3]=address[3];
            end
          endcase
          nextState++;
        end
        else if (state>=stateRead7_4 && state<=stateRead3_0) begin
          case (state)
            stateRead7_4: begin
              byteToRead[4]=io_psram_data0;
              byteToRead[5]=io_psram_data1;
              byteToRead[6]=io_psram_data2;
              byteToRead[7]=io_psram_data3;
            end

            stateRead3_0: begin
              byteToRead[0]=io_psram_data0;
              byteToRead[1]=io_psram_data1;
              byteToRead[2]=io_psram_data2;
              byteToRead[3]=io_psram_data3;
              psram_cs=HIGH;
              nextState=stateIdle;
              isBusy=0;
              dataReady=1;
            end
          endcase
          if (state!=stateIdle) nextState++;
        end
        else if (state>=stateWrite_SendWriteCmd_1 && state<=stateWrite_SendWriteCmd_7) begin
          case (state)
            stateWrite_SendWriteCmd_1: dataU7[0]=SPIQuadWrite[6];
            stateWrite_SendWriteCmd_2: dataU7[0]=SPIQuadWrite[5];
            stateWrite_SendWriteCmd_3: dataU7[0]=SPIQuadWrite[4];
            stateWrite_SendWriteCmd_4: dataU7[0]=SPIQuadWrite[3];
            stateWrite_SendWriteCmd_5: dataU7[0]=SPIQuadWrite[2];
            stateWrite_SendWriteCmd_6: dataU7[0]=SPIQuadWrite[1];
            stateWrite_SendWriteCmd_7: dataU7[0]=SPIQuadWrite[0];
          endcase
          nextState++;
        end
        else if (state>=stateWrite_SendAddr23_20 && state<=stateWrite_SendAddr3_0) begin
          case (state)
            stateWrite_SendAddr23_20: begin
              dataU7[0]=address[20];
              dataU7[1]=address[21];
              dataU7[2]=address[22];
              dataU7[3]=address[23];
            end

            stateWrite_SendAddr19_16: begin
              dataU7[0]=address[16];
              dataU7[1]=address[17];
              dataU7[2]=address[18];
              dataU7[3]=address[19];
            end

            stateWrite_SendAddr15_12: begin
              dataU7[0]=address[12];
              dataU7[1]=address[13];
              dataU7[2]=address[14];
              dataU7[3]=address[15];
            end

            stateWrite_SendAddr11_8: begin
              dataU7[0]=address[8];
              dataU7[1]=address[9];
              dataU7[2]=address[10];
              dataU7[3]=address[11];
            end

            stateWrite_SendAddr7_4: begin
              dataU7[0]=address[4];
              dataU7[1]=address[5];
              dataU7[2]=address[6];
              dataU7[3]=address[7];
            end

            stateWrite_SendAddr3_0: begin
              dataU7[0]=address[0];
              dataU7[1]=address[1];
              dataU7[2]=address[2];
              dataU7[3]=address[3];
            end
          endcase
          nextState++;
        end
        else if (state>=stateWrite_SendData7_4 && state<=stateWrite_SendData3_0) begin
          case (state)
            stateWrite_SendData7_4: begin
              dataU7[0]=byteToWrite[4];
              dataU7[1]=byteToWrite[5];
              dataU7[2]=byteToWrite[6];
              dataU7[3]=byteToWrite[7];
              nextState++;
            end

            stateWrite_SendData3_0: begin
              dataU7[0]=byteToWrite[0];
              dataU7[1]=byteToWrite[1];
              dataU7[2]=byteToWrite[2];
              dataU7[3]=byteToWrite[3];
              psram_cs=HIGH;
              nextState=stateIdle;
              isBusy=0;
            end
          endcase
        end
        else if (state>=stateRead_WaitCycle_1 && state<=stateRead_WaitCycle_7) begin
          direction=READ;
          nextState++;
        end
      end
    endcase
  end

endmodule

`endif