// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

`ifndef MEMCTRL_H
`define MEMCTRL_H

`include "memCtrl.vh"

/* 24-bit address, 8-Bit memory controller interface using 2x LY68S3200 
   32M (4Mx8) Bits Serial Pseudo-SRAM with QPI divided into 2 banks. */

module memCtrl( input logic i_clkRAM,  // RAM clock (100Mhz)
                input logic reset,
                input logic i_cs,    // 0-enable
                input logic i_write, // 0-read, 1-write
                input logic [23:0] i_address, // 24-bit address
                input logic i_bank, // 0- U7, 1- U9
                output wire o_psram_sclk,                
                input  logic [7:0] i_dataToWrite,
                output logic [7:0] o_dataRead,
                inout wire io_psram_data0,
                inout wire io_psram_data1,
                inout wire io_psram_data2,
                inout wire io_psram_data3,
                inout wire io_psram_data4,                
                inout wire io_psram_data5,
                inout wire io_psram_data6,
                inout wire io_psram_data7,            
                output wire o_psram_cs,
                output logic o_busy, // 1-Busy
                output logic o_dataReady, // 1-ready);
                output o_led); 

  parameter initDelayInClkCyles=15000; // 150us @ 100Mhz
  
  reg [3:0] dataU7; // Bank 0
  reg [3:0] dataU9; // Bank 1
  reg [7:0] qpiCommand;
  
  Action action;

  // Use for debugging purposes only
  logic led;
  //assign o_led=!led;

  reg [23:0] address;
  logic [15:0] delayCounter;
  StateMachine state, next;
   
  reg [7:0] byteToWrite;
  reg psram_cs=1;
  reg psram_cs2=0;
  
  reg[5:0] shifter;
 
  logic psram_sclk;
  assign o_psram_sclk= reset ? i_clkRAM : 0;

  // Direction direction; // 0- in (read), 1-out (write)
  reg [7:0] direction;
  logic csTriggeredOld;
  logic isInitialized=0;

  assign io_psram_data0=(direction[0]==1 ? dataU7[0] : 1'bZ);
  assign io_psram_data1=(direction[1]==1 ? dataU7[1] : 1'bZ);
  assign io_psram_data2=(direction[2]==1 ? dataU7[2] : 1'bZ);
  assign io_psram_data3=(direction[3]==1 ? dataU7[3] : 1'bZ);

  assign io_psram_data4=(direction[4]==1 ? dataU9[0] : 1'bZ);
  assign io_psram_data5=(direction[5]==1 ? dataU9[1] : 1'bZ);
  assign io_psram_data6=(direction[6]==1 ? dataU9[2] : 1'bZ);
  assign io_psram_data7=(direction[7]==1 ? dataU9[3] : 1'bZ);

  assign o_psram_cs= psram_cs2==1 ? 0 : psram_cs;

  always_ff @(posedge i_clkRAM or negedge reset) 
    if (!reset) state<=stateXXX;
    else state<=next;  
  
  // PSRAM needs pulling down CS on falling edge to really be stable
  always @(negedge i_clkRAM)
   case (next)
    sendQPIEnable:    psram_cs2=1;
    sendQPIWriteCmd:  psram_cs2=1;
    sendQPIReadCmd:   psram_cs2=1;
    default:          psram_cs2=0;
                      
   endcase

  // next logic
  always_comb begin
    case (state)
      stateXXX:               next=stateReset;

      stateReset:             next=delayAfterReset;

      delayAfterReset:
        if (delayCounter==0) begin
          if (!isInitialized) next=sendQPIEnable;
          else                next=stateIdle;
        end
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
        if (shifter>15+WAITCYCLES) next=stateIdle;
        else                    next=readData;

      writeData:
        if (shifter==16)        next=stateIdle;
        else                    next=writeData;

      default:                  next=stateXXX;
    endcase
  end
  
  always_ff @(posedge i_clkRAM or negedge reset) begin
  
    if (!reset) begin
      isInitialized<=0;
      delayCounter<=0;
      direction<=0;
      o_dataRead<=0;
      byteToWrite<=0;
      shifter<=0;
      o_dataReady<=0;
      address<=0;
      qpiCommand<=0;
      o_busy<=1;
      dataU7<=4'b0;
      dataU9<=4'b0;
      csTriggeredOld<=0;
      action<=DONOTHING;
      psram_cs<=`HIGH;
    end
    else begin
      o_busy<= !(next==stateIdle && action==DONOTHING);
      direction<='0;

      if (i_cs==0) begin
        if (!o_busy) begin
          if (csTriggeredOld==0) begin            
            csTriggeredOld<=1;
            shifter<=0;
            o_dataReady<=0;
            if (i_write) begin
                action<=DOWRITE;
                qpiCommand<=SPIQuadWrite;
                byteToWrite<=i_dataToWrite;
                o_busy<=1;
            end
            else begin
              action<=DOREAD;
              qpiCommand<=SPIQuadRead;
              o_busy<=1;
            end
            address<=i_address;
          end
        end
      end
      else csTriggeredOld<=0;

      case (next) 
        stateReset: begin
          psram_cs<=`HIGH;
          o_dataReady<=0;
          action<=DONOTHING;
          delayCounter<=initDelayInClkCyles;
        end

        delayAfterReset: begin 
          psram_cs<=`HIGH;
          qpiCommand<=enableQPIModeCmd;
          shifter<=0;
          delayCounter<=delayCounter-1;
        end

        sendQPIEnable: begin
          psram_cs<=`LOW;
          direction<=8'b00010001; // SI active only on both chips
          dataU7[0]<=qpiCommand[shifter^7];
          dataU9[0]<=qpiCommand[shifter^7];
          shifter<=shifter+1;        
          isInitialized<=1;
        end    

        stateIdle: begin
          psram_cs<=`HIGH;
          direction<=8'b0; // all 'Z', stay put
          case (action)
            DOWRITE: begin
              o_dataReady<=0;
              qpiCommand<=SPIQuadWrite;
              shifter<=0;   
              psram_cs<=`LOW;
            end
            DOREAD: begin
              o_dataReady<=0;
              qpiCommand<=SPIQuadRead;
              shifter<=0;                                     
              psram_cs<=`LOW;
            end
            DONOTHING: ;
            default: ;
          endcase
        end

        sendQPIWriteCmd, 
        sendQPIReadCmd: begin
          psram_cs<=`LOW;
          if (!i_bank) begin
            direction<=8'b00001111;
            if (shifter<4) dataU7[3:0]<=qpiCommand[7:4];
            else dataU7[3:0]<=qpiCommand[3:0];
          end
          else begin
            direction<=8'b11110000; // QPI enabled. Use all data lines to send EB (read) or 38 (write)
            if (shifter<4) dataU9[3:0]<=qpiCommand[7:4];
            else dataU9[3:0]<=qpiCommand[3:0];
          end
          shifter<=shifter+4; 
        end

        sendQPIAddress: begin
          psram_cs<=`LOW;
          direction<=8'b00001111; // all pins active
          if (i_bank) direction<=8'b11110000; // all pins active
          case (shifter) 
            8:  if (!i_bank) dataU7[3:0]<=address[23:20];
                else dataU9[3:0]<=address[23:20];
            9:  if (!i_bank) dataU7[3:0]<=address[19:16];
                else dataU9[3:0]<=address[19:16];
            10: if (!i_bank) dataU7[3:0]<=address[15:12];
                else dataU9[3:0]<=address[15:12];      
            11: if (!i_bank) dataU7[3:0]<=address[11:8];
                else dataU9[3:0]<=address[11:8];
            12: if (!i_bank) dataU7[3:0]<=address[7:4];
                else dataU9[3:0]<=address[7:4];
            13: if (!i_bank) dataU7[3:0]<=address[3:0];
                else dataU9[3:0]<=address[3:0];
          endcase
          shifter<=shifter+1;        
        end

        writeData: begin
          psram_cs<=`LOW;
          direction<=8'b00001111; // all pins active
          if (i_bank) direction<=8'b11110000; // all pins active
          case (shifter) 
            14: if (!i_bank) dataU7[3:0]<=byteToWrite[7:4];
                else dataU9[3:0]<=byteToWrite[7:4];      
            15: begin
                  if (!i_bank) dataU7[3:0]<=byteToWrite[3:0];
                  else dataU9[3:0]<=byteToWrite[3:0];
                  action<=DONOTHING;
                  o_busy<=0;
                end
          endcase
          shifter<=shifter+1;      
        end

        /* We have to wait for the psram to fetch our data before we can
            actually read after having sent the address. */

        readData: begin
          psram_cs<=`LOW;
          direction<=8'b0; // do not drive io_psram
          case (shifter) 
            14+WAITCYCLES: begin
                  if (!i_bank) begin
                    o_dataRead[4]<=io_psram_data0;
                    o_dataRead[5]<=io_psram_data1;
                    o_dataRead[6]<=io_psram_data2;
                    o_dataRead[7]<=io_psram_data3;
                  end
                  else begin
                    o_dataRead[4]<=io_psram_data4;
                    o_dataRead[5]<=io_psram_data5;
                    o_dataRead[6]<=io_psram_data6;
                    o_dataRead[7]<=io_psram_data7;
                  end
                end  
            15+WAITCYCLES: begin
                  if (!i_bank) begin
                    o_dataRead[0]<=io_psram_data0;
                    o_dataRead[1]<=io_psram_data1;
                    o_dataRead[2]<=io_psram_data2;
                    o_dataRead[3]<=io_psram_data3;
                  end
                  else begin
                    o_dataRead[0]<=io_psram_data4;
                    o_dataRead[1]<=io_psram_data5;
                    o_dataRead[2]<=io_psram_data6;
                    o_dataRead[3]<=io_psram_data7;
                  end                                      
                  action<=DONOTHING;
                  o_dataReady<=1;
                  o_busy<=0;
                end 

            default: // Waitcyles
              direction<=8'b0; // all Z
          endcase
          shifter<=shifter+1;               
        end
        default: ;        
      endcase
    end
  end
endmodule
`endif 


  
  
