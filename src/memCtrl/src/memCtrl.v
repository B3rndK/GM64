// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef MEMCTRL_H
`define MEMCTRL_H

/* 8-Bit Memory controller interface using LY68S3200 
   32M (4Mx8) Bits Serial Pseudo-SRAM with SPI and QPI.
   Single bytes are written 4x, so error correction would be possible 
   by comparing the four bytes for equality (and taking the highest occuring value)
   when in doubt, but this is not (yet) implemented. */

typedef enum {
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

typedef enum  {
  READ=0,
  WRITE=1
} Direction;


module memCtrl( input wire clk,
                input wire reset,
                input wire CE,    // 1-enable
                input wire write, // 0-read, 1-write
                input reg [5:0]  bank,  // bank 0-31, each of 64KB = 2097152 bytes
                input reg [15:0] addrBus,
                output wire o_psram_sclk,                
                input reg [7:0] dataToWrite,
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
                output reg isBusy, // 1-busy
                output reg o_dataReady,
                output reg [7:0] debug); 
  
  reg dataU7[3:0];
  reg dataU9[3:0];
  Direction direction; // 1- in (read), 0-out (write)

  assign io_psram_data0=direction==READ ? 1'bZ : dataU7[0];
  assign io_psram_data1=direction==READ ? 1'bZ : dataU7[1];
  assign io_psram_data2=direction==READ ? 1'bZ : dataU7[2];
  assign io_psram_data3=direction==READ ? 1'bZ : dataU7[3];

  assign io_psram_data4=direction==READ ? 1'bZ : dataU9[0];
  assign io_psram_data5=direction==READ ? 1'bZ : dataU9[1];
  assign io_psram_data6=direction==READ ? 1'bZ : dataU9[2];
  assign io_psram_data7=direction==READ ? 1'bZ : dataU9[3];

  assign  dataRead[0]=o_dataReady ? byteToRead[0] : 1'bZ;
  assign  dataRead[1]=o_dataReady ? byteToRead[1] : 1'bZ; 
  assign  dataRead[2]=o_dataReady ? byteToRead[2] : 1'bZ; 
  assign  dataRead[3]=o_dataReady ? byteToRead[3] : 1'bZ; 
  assign  dataRead[4]=o_dataReady ? byteToRead[4] : 1'bZ; 
  assign  dataRead[5]=o_dataReady ? byteToRead[5] : 1'bZ; 
  assign  dataRead[6]=o_dataReady ? byteToRead[6] : 1'bZ; 
  assign  dataRead[7]=o_dataReady ? byteToRead[7] : 1'bZ; 
    
  reg [24:0] address;
  
  // Loops through 3-0 to reuse write state, writing 4x same byte
  reg [3:0] byteToSendCounter;

  parameter LOW=1'b0;
  parameter HIGH=1'b1;
 
  parameter initDelayInClkCyles=15000; // 150us @100Mhz
  reg [15:0] delayCounter;
 
  wire CS;

  reg [5:0] state;
  
  reg [7:0] qpiCmd;

  reg [7:0] byteToWrite;
  reg [7:0] byteToRead;
  

//  reg isBusy;
//  assign busy=isBusy;
  reg psram_cs;
  assign o_psram_cs=psram_cs;
  shortint shifter;
 
  reg psram_sclk;
  assign o_psram_sclk=clk==1 ? 1:0;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state<=stateReset;
      direction<=READ;
      o_dataReady<=0;
      psram_cs<=HIGH;
      isBusy<=1;
      // U7
      dataU7[0]<=1'bZ;
      dataU7[1]<=1'bZ;
      dataU7[2]<=1'bZ;
      dataU7[3]<=1'bZ;
      
      // U9
      dataU9[0]<=1'bZ;
      dataU9[1]<=1'bZ;
      dataU9[2]<=1'bZ;
      dataU9[3]<=1'bZ;
    end
    else case (state)

      stateReset: begin
        state<=stateInit_1;
      end

      stateInit_1: begin
        delayCounter--;
        if (delayCounter==0) begin
          state<=stateInit_2;
        end
      end
      stateInit_2: begin // Enable QPI mode
        shifter<=0;
        state<=stateEnableQPI;
      end

      stateEnableQPI: begin // Enable QPI mode
        direction<=WRITE;
        case (shifter)
          0: begin
            psram_cs<=LOW;
            dataU7[0]<=enableQPIMode[7];    
            dataU7[1]<=1'bZ;
            dataU7[2]<=1'bZ;
            dataU7[3]<=1'bZ;
            dataU9[0]<=enableQPIMode[7];
            dataU9[1]<=1'bZ;
            dataU9[2]<=1'bZ;
            dataU9[3]<=1'bZ;
          end
          1: begin
            dataU7[0]<=enableQPIMode[6];    
            dataU9[0]<=enableQPIMode[6];
          end
          2: begin
            dataU7[0]<=enableQPIMode[5];    
            dataU9[0]<=enableQPIMode[5];
          end
          3: begin
            dataU7[0]<=enableQPIMode[4];    
            dataU9[0]<=enableQPIMode[4];
          end
          4: begin
            dataU7[0]<=enableQPIMode[3];    
            dataU9[0]<=enableQPIMode[3];
          end
          5: begin
            dataU7[0]<=enableQPIMode[2];    
            dataU9[0]<=enableQPIMode[2];
          end
          6: begin
            dataU7[0]<=enableQPIMode[1];    
            dataU9[0]<=enableQPIMode[1];
          end
          7: begin
            dataU7[0]<=enableQPIMode[0];    
            dataU9[0]<=enableQPIMode[0];
            psram_cs<=HIGH;
            state<=stateIdle;
          end
          default:
            ;
        endcase
        shifter++;
      end

      stateIdle: begin
        if (CE) begin
          direction<=WRITE;
          o_dataReady<=0;
          isBusy<=1;
          byteToWrite<=dataToWrite;
          address<=addrBus<<3;  
          address[23]<=bank[4];  
          address[22]<=bank[3];
          address[21]<=bank[2];
          address[20]<=bank[1];
          address[19]<=bank[0];  
          dataU7[1]<=1'bZ;
          dataU7[2]<=1'bZ;
          dataU7[3]<=1'bZ;

          if (write) begin
            state<=stateWrite_SendWriteCmd_1;
            dataU7[0]<=SPIQuadWrite[7];
            //byteToSendCounter=4;
          end
          else begin
            state<=stateRead_SendReadCmd_1;
            dataU7[0]<=SPIQuadRead[7];
          end
          psram_cs<=LOW;
        end
        else begin
          isBusy<=0;
          direction<=READ;
        end
      end

      default:
        if (state>=stateRead_SendReadCmd_1 && state<=stateRead_SendReadCmd_7) begin
          case (state)
            stateRead_SendReadCmd_1: dataU7[0]<=SPIQuadRead[6];
            stateRead_SendReadCmd_2: dataU7[0]<=SPIQuadRead[5];
            stateRead_SendReadCmd_3: dataU7[0]<=SPIQuadRead[4];
            stateRead_SendReadCmd_4: dataU7[0]<=SPIQuadRead[3];
            stateRead_SendReadCmd_5: dataU7[0]<=SPIQuadRead[2];
            stateRead_SendReadCmd_6: dataU7[0]<=SPIQuadRead[1];
            stateRead_SendReadCmd_7: dataU7[0]<=SPIQuadRead[0];
          endcase
          state++;
        end 
        else if (state>=stateRead_SendAddr23_20 && state<=stateRead_SendAddr3_0) begin
          case (state)
            stateRead_SendAddr23_20: begin
              dataU7[0]<=address[20];
              dataU7[1]<=address[21];
              dataU7[2]<=address[22];
              dataU7[3]<=address[23];
            end

            stateRead_SendAddr19_16: begin
              dataU7[0]<=address[16];
              dataU7[1]<=address[17];
              dataU7[2]<=address[18];
              dataU7[3]<=address[19];
            end

            stateRead_SendAddr15_12: begin
              dataU7[0]<=address[12];
              dataU7[1]<=address[13];
              dataU7[2]<=address[14];
              dataU7[3]<=address[15];
            end

            stateRead_SendAddr11_8: begin
              dataU7[0]<=address[8];
              dataU7[1]<=address[9];
              dataU7[2]<=address[10];
              dataU7[3]<=address[11];
            end

            stateRead_SendAddr7_4: begin
              dataU7[0]<=address[4];
              dataU7[1]<=address[5];
              dataU7[2]<=address[6];
              dataU7[3]<=address[7];
            end

            stateRead_SendAddr3_0: begin
              dataU7[0]<=address[0];
              dataU7[1]<=address[1];
              dataU7[2]<=address[2];
              dataU7[3]<=address[3];
            end
          endcase
          state++;
        end
        else if (state>=stateRead7_4 && state<=stateRead3_0) begin
          case (state)
            stateRead7_4: begin
              byteToRead[4]<=io_psram_data0;
              byteToRead[5]<=io_psram_data1;
              byteToRead[6]<=io_psram_data2;
              byteToRead[7]<=io_psram_data3;
            end

            stateRead3_0: begin
              byteToRead[0]<=io_psram_data0;
              byteToRead[1]<=io_psram_data1;
              byteToRead[2]<=io_psram_data2;
              byteToRead[3]<=io_psram_data3;
              psram_cs<=HIGH;
              state<=stateIdle;
              isBusy<=0;
              o_dataReady<=1;
            end
          endcase
          if (state!=stateIdle) state++;
        end
        else if (state>=stateWrite_SendWriteCmd_1 && state<=stateWrite_SendWriteCmd_7) begin
          case (state)
            stateWrite_SendWriteCmd_1: dataU7[0]<=SPIQuadWrite[6];
            stateWrite_SendWriteCmd_2: dataU7[0]<=SPIQuadWrite[5];
            stateWrite_SendWriteCmd_3: dataU7[0]<=SPIQuadWrite[4];
            stateWrite_SendWriteCmd_4: dataU7[0]<=SPIQuadWrite[3];
            stateWrite_SendWriteCmd_5: dataU7[0]<=SPIQuadWrite[2];
            stateWrite_SendWriteCmd_6: dataU7[0]<=SPIQuadWrite[1];
            stateWrite_SendWriteCmd_7: dataU7[0]<=SPIQuadWrite[0];
          endcase
          state++;
        end
        else if (state>=stateWrite_SendAddr23_20 && state<=stateWrite_SendAddr3_0) begin
          case (state)
            stateWrite_SendAddr23_20: begin
              dataU7[0]<=address[20];
              dataU7[1]<=address[21];
              dataU7[2]<=address[22];
              dataU7[3]<=address[23];
            end

            stateWrite_SendAddr19_16: begin
              dataU7[0]<=address[16];
              dataU7[1]<=address[17];
              dataU7[2]<=address[18];
              dataU7[3]<=address[19];
            end

            stateWrite_SendAddr15_12: begin
              dataU7[0]<=address[12];
              dataU7[1]<=address[13];
              dataU7[2]<=address[14];
              dataU7[3]<=address[15];
            end

            stateWrite_SendAddr11_8: begin
              dataU7[0]<=address[8];
              dataU7[1]<=address[9];
              dataU7[2]<=address[10];
              dataU7[3]<=address[11];
            end

            stateWrite_SendAddr7_4: begin
              dataU7[0]<=address[4];
              dataU7[1]<=address[5];
              dataU7[2]<=address[6];
              dataU7[3]<=address[7];
            end

            stateWrite_SendAddr3_0: begin
              dataU7[0]<=address[0];
              dataU7[1]<=address[1];
              dataU7[2]<=address[2];
              dataU7[3]<=address[3];
            end
          endcase
          state++;
        end
        else if (state>=stateWrite_SendData7_4 && state<=stateWrite_SendData3_0) begin
          case (state)
            stateWrite_SendData7_4: begin
              dataU7[0]<=byteToWrite[4];
              dataU7[1]<=byteToWrite[5];
              dataU7[2]<=byteToWrite[6];
              dataU7[3]<=byteToWrite[7];
              state++;
            end

            stateWrite_SendData3_0: begin
              dataU7[0]<=byteToWrite[0];
              dataU7[1]<=byteToWrite[1];
              dataU7[2]<=byteToWrite[2];
              dataU7[3]<=byteToWrite[3];
              /* if (byteToSendCounter>1) state-=2;
              else psram_cs=HIGH;*/
              psram_cs<=HIGH;
              state<=stateIdle;
              debug<=3;
              isBusy<=0;
            end
          endcase
        end
        else if (state>=stateRead_WaitCycle_1 && state<=stateRead_WaitCycle_7) begin
          direction<=READ;
          state++;
        end
      endcase
  end
endmodule

`endif