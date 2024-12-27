// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef MEMCTRL_H
`define MEMCTRL_H

/* 8-Bit Memory controller interface using LY68S3200 
   32M (4Mx8) Bits Serial Pseudo-SRAM with SPI and QPI. */

typedef enum bit[7:0] {
  stateReset=0,
  delayAfterReset=1,
  sendQPIEnable=3,
  stateIdle=10,
  sendQPIWriteCmd=11,
  
  sendQPIAddress=12,
  writeData=20,

  sendQPIReadCmd=60,
  readData=61,

  waitCycle=80,

  stateXXX=92
 
} StateMachine;

typedef enum reg[7:0] {
  enableQPIModeCmd=8'b00110101,
  SPIQuadWrite=8'b00111000,
  SPIQuadRead=8'heb
} QPICommands;

typedef enum reg  {
  READ=0,
  WRITE=1
} Direction;

typedef enum bit[1:0]  {
  DONOTHING=0,
  DOREAD=1,
  DOWRITE=2,
  XXX=3
} Action;

 localparam WAITCYCLES = 6;

module memCtrl( input wire i_clkRAM,  // RAM clock (100Mhz)
                input wire reset,
                input wire i_cs,    // 0-enable
                input wire i_write, // 0-read, 1-write
                input wire [23:0] i_address, // 24-bit address
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
                output wire o_Busy, // 1-Busy
                output wire o_dataReady); 

  reg [3:0] dataU7;
  reg [3:0] dataBufferU7;
  
  reg [3:0] dataU9;
  reg [3:0] dataBufferU9;

  reg isWrite;
  reg [7:0] qpiCommand;

  /* Output */
  reg oBusy;
  assign o_Busy=oBusy;

  Action action;
  
  assign  dataRead[0]=dataReady ? byteToRead[0] : 1'bZ;
  assign  dataRead[1]=dataReady ? byteToRead[1] : 1'bZ; 
  assign  dataRead[2]=dataReady ? byteToRead[2] : 1'bZ; 
  assign  dataRead[3]=dataReady ? byteToRead[3] : 1'bZ; 
  assign  dataRead[4]=dataReady ? byteToRead[4] : 1'bZ; 
  assign  dataRead[5]=dataReady ? byteToRead[5] : 1'bZ; 
  assign  dataRead[6]=dataReady ? byteToRead[6] : 1'bZ; 
  assign  dataRead[7]=dataReady ? byteToRead[7] : 1'bZ; 

  reg dataReady;        
  assign o_dataReady=dataReady;

  reg [23:0] address;

  // Loops through 3-0 to reuse write state, writing 4x same byte
  reg [3:0] byteToSendCounter;

  parameter LOW=1'b0;
  parameter HIGH=1'b1;
 
  integer initDelayInClkCyles=15000; // 150us @ 100Mhz
  integer delayCounter;
  
  StateMachine state, next;
    
  reg [7:0] byteToWrite;
  reg [7:0] byteToRead;
  
  reg psram_cs;
  assign o_psram_cs= psram_cs;
  
  reg[5:0] shifter;
 
  reg psram_sclk;
  assign o_psram_sclk=i_clkRAM;

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

  
  always_ff @(posedge i_clkRAM or negedge reset) 
    if (!reset) state<=stateXXX;
    else state<=next;  
  
  // next logic
  always_comb begin
    next=stateXXX;
    case (state)

      stateXXX:               next=stateReset;
      
      stateReset:
                              next=delayAfterReset;
      delayAfterReset:
        if (delayCounter==0)  next=sendQPIEnable;
        else                  next=delayAfterReset;        
      
      sendQPIEnable:      
        if (shifter==8)       next=stateIdle;
        else                  next=sendQPIEnable;
    
      stateIdle: begin
        case (action)
          DONOTHING:          next=stateIdle;
          DOWRITE:            next=sendQPIWriteCmd;
          DOREAD:             next=sendQPIReadCmd;
          default:            next=stateIdle;
        endcase
      end
      
      sendQPIWriteCmd:
        if (shifter==8)         next=sendQPIAddress;
        else                    next=sendQPIWriteCmd;
      
      sendQPIReadCmd:
        if (shifter==8)         next=sendQPIAddress;
        else                    next=sendQPIReadCmd;

      sendQPIAddress:
        if (shifter==14)
        begin
          if (action==DOWRITE)  next=writeData;
          else                  next=readData;
        end
        else                    next=sendQPIAddress;
                                
      readData:
        if (shifter==14+WAITCYCLES+2) next=stateIdle;
        else                    next=readData;

      writeData:
        if (shifter==16)        next=stateIdle;
        else                    next=writeData;

    endcase
  end
  

  always_ff @(posedge i_clkRAM or negedge reset) begin

    oBusy<=1;
    dataU7<=4'bZ;
    dataU9<=4'bZ;
    psram_cs<=HIGH;
    direction<='0;
    
    if (!reset) begin
      dataReady<=0;
    end
    else begin
      if (i_cs==0) begin
        shifter<=0;
        if (i_write) begin
            action<=DOWRITE;
            qpiCommand<=SPIQuadWrite;
            byteToWrite<=dataToWrite;
        end
        else begin
          action<=DOREAD;
          qpiCommand<=SPIQuadRead;
        end
        address<=i_address;
      end
      else
        case (next) 
          stateReset: begin
            delayCounter<=initDelayInClkCyles;
          end

          delayAfterReset: begin 
            delayCounter<=delayCounter-1;
            qpiCommand<=enableQPIModeCmd;
            shifter<=0;
          end

          sendQPIEnable: begin
            psram_cs<=LOW;
            direction<=8'b00010001; // SI active only
            dataU7[0]<=qpiCommand[shifter^7];
            dataU9[0]<=qpiCommand[shifter^7];
            shifter<=shifter+1;        
          end    

          stateIdle: begin
            psram_cs<=HIGH;
            direction<=8'b00000000; // all 'Z'
            case (action)
              DOWRITE: begin
                dataReady<=0;
                qpiCommand<=SPIQuadWrite;
                shifter<=0;           
              end
              DOREAD: begin
                dataReady<=0;
                qpiCommand<=SPIQuadRead;
                shifter<=0;                                     
              end
              DONOTHING: 
                oBusy<=0;
            endcase
          end

          sendQPIWriteCmd, 
          sendQPIReadCmd: begin
            psram_cs<=LOW;
            direction<=8'b00010001; // SI active only
            dataU7[0]<=qpiCommand[shifter^7];
            dataU9[0]<=qpiCommand[shifter^7];        
            shifter<=shifter+1; 
          end

          sendQPIAddress: begin
            psram_cs<=LOW;
            direction<=8'b11111111; // all pins active
            case (shifter) 
              8:  begin
                    dataU7[0]<=address[20];
                    dataU7[1]<=address[21];
                    dataU7[2]<=address[22];
                    dataU7[3]<=address[23];
                  end
              9:  begin
                    dataU7[0]<=address[16];
                    dataU7[1]<=address[17];
                    dataU7[2]<=address[18];
                    dataU7[3]<=address[19];
                  end
              10: begin
                    dataU7[0]<=address[12];
                    dataU7[1]<=address[13];
                    dataU7[2]<=address[14];
                    dataU7[3]<=address[15];
                  end
              11: begin
                    dataU7[0]<=address[8];
                    dataU7[1]<=address[9];
                    dataU7[2]<=address[10];
                    dataU7[3]<=address[11];
                  end
              12: begin
                    dataU7[0]<=address[4];
                    dataU7[1]<=address[5];
                    dataU7[2]<=address[6];
                    dataU7[3]<=address[7];
                  end
              13: begin
                    dataU7[0]<=address[0];
                    dataU7[1]<=address[1];
                    dataU7[2]<=address[2];
                    dataU7[3]<=address[3];
                  end
            endcase
            shifter<=shifter+1;        
          end

          writeData: begin
            psram_cs<=LOW;
            direction<=8'b11111111; // all pins active
            case (shifter) 
              14: begin
                    dataU7[0]<=byteToWrite[4];
                    dataU7[1]<=byteToWrite[5];
                    dataU7[2]<=byteToWrite[6];
                    dataU7[3]<=byteToWrite[7];
                  end  
              15: begin
                    dataU7[0]<=byteToWrite[0];
                    dataU7[1]<=byteToWrite[1];
                    dataU7[2]<=byteToWrite[2];
                    dataU7[3]<=byteToWrite[3];
                    action<=DONOTHING;
                  end  
            endcase
            shifter<=shifter+1;        
          end

          /* We have to wait for the psram to fetch our data before we can
             actually read after having sent the address. */

          readData: begin
            psram_cs<=LOW;
            direction<=8'b11111111; // all pins active
            case (shifter) 
              14+WAITCYCLES: begin
                    byteToRead[4]<=io_psram_data0;
                    byteToRead[5]<=io_psram_data1;
                    byteToRead[6]<=io_psram_data2;
                    byteToRead[7]<=io_psram_data3;
                  end  
              15+WAITCYCLES: begin
                    byteToRead[0]<=io_psram_data0;
                    byteToRead[1]<=io_psram_data1;
                    byteToRead[2]<=io_psram_data2;
                    byteToRead[3]<=io_psram_data3;
                    action<=DONOTHING;
                    dataReady<=1;
                  end  

              default: // Waitcyles
                direction<=8'b0; // all Z
            endcase
            shifter<=shifter+1;        
          end

        endcase
    end
 end

endmodule
`endif 


  
  
