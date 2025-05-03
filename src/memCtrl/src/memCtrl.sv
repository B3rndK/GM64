// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

`timescale 1us / 1ns
`include "memCtrl.vh"

`default_nettype none

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
                output logic o_psram_cs,
                output logic o_busy, // 1-Busy
                output logic o_dataReady,
                output StateMachine o_state,
                output logic led); // 1-ready

  parameter initDelayInClkCyles=15400; // 150us @ 100Mhz+some bonus
  localparam WAITCYCLES=6;
  reg [3:0] dataU7; // Bank 0
  reg [3:0] dataU9; // Bank 1
  reg [7:0] qpiCommand;
  
`define LOW   1'b0;
`define HIGH  1'b1;

 Action action;
 logic stopClock;
   
  
  logic[3:0] cntWaitCycles;
  reg [23:0] address;
  logic bank;
  logic [15:0] delayCounter;
  StateMachine state, next;
   
  reg [7:0] byteToWrite;
  reg psram_cs=0;
  
  reg[5:0] shifter;
 
  assign o_psram_sclk= stopClock ? 0 : i_clkRAM;

  // Direction direction; // 0- in (read), 1-out (write)
  reg [7:0] direction;
  logic isInitialized;

  assign io_psram_data0=(direction[0]==1 ? dataU7[0] : 1'bZ);
  assign io_psram_data1=(direction[1]==1 ? dataU7[1] : 1'bZ);
  assign io_psram_data2=(direction[2]==1 ? dataU7[2] : 1'bZ);
  assign io_psram_data3=(direction[3]==1 ? dataU7[3] : 1'bZ);

  assign io_psram_data4=(direction[4]==1 ? dataU9[0] : 1'bZ);
  assign io_psram_data5=(direction[5]==1 ? dataU9[1] : 1'bZ);
  assign io_psram_data6=(direction[6]==1 ? dataU9[2] : 1'bZ);
  assign io_psram_data7=(direction[7]==1 ? dataU9[3] : 1'bZ);

  assign o_psram_cs= psram_cs;
  
  always_ff @(posedge i_clkRAM) 
    if (!reset) state<=stateXXX;
    else state<=next;  

  // PSRAM needs pulling down CS on falling edge to really be stable
  always_ff @(negedge i_clkRAM)

    case (next)
      stateXXX:         psram_cs<=0;         
      stateReset:       psram_cs<=0;
      sendQPIEnable:    psram_cs<=0;
      sendQPIWriteCmd:  psram_cs<=0;
      sendQPIAddress:   psram_cs<=0;
      writeData:        psram_cs<=0;
      readData:         psram_cs<=0;       
      waitCycles:       psram_cs<=0;
      sendQPIReadCmd:   psram_cs<=0;
      stateIdle:        psram_cs<=1;        
      default:          psram_cs<=1;
    endcase

  // next logic
  always_comb begin
    case (state)
      stateXXX:               begin                                
                                next=stateReset;
                              end

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
        if (shifter==13 && action==DOWRITE) next=writeData;
        else if (shifter==14 && action==DOREAD) next=waitCycles;
        else next=sendQPIAddress; 
             
      waitCycles:
        if (cntWaitCycles==1)   next=readData;
        else                    next=waitCycles;                   
      
      readData: 
        if (o_dataReady)        next=stateIdle;
        else                    next=readData;
      
      writeData:
        if (shifter==16)        next=stateIdle;
        else                    next=writeData;

      default:                  next=stateXXX;
    endcase
  end
  
  always_ff @(posedge i_clkRAM) begin
    if (!reset) begin
      o_dataRead<=0;
      bank<=0;
      o_dataReady<=0;
      action<=DONOTHING;
      isInitialized<=0;
      delayCounter<=0;
      direction<='hff;
      byteToWrite<=0;
      shifter<=0;
      address<=0;
      qpiCommand<=0;
      o_busy<=1;
      dataU7<=4'b0;
      dataU9<=4'b0;
      stopClock<=1;
      led<=0;
    end
    else begin
      o_state<=state;
      o_busy<=1;
      isInitialized<=1;      

      case (next) 
        stateReset: begin
          direction<=8'hff;
          action<=DONOTHING;
          delayCounter<=initDelayInClkCyles;
          isInitialized<=0;      
        end

        delayAfterReset: begin 
          isInitialized<=0;      
          qpiCommand<=enableQPIModeCmd;
          shifter<=0;
          delayCounter<=delayCounter-1;
          if (delayCounter==3) stopClock<=0;
        end

        sendQPIEnable: begin
          isInitialized<=0;      
          direction<=8'b00010001; // SI active only on both chips
          dataU7[0]<=qpiCommand[shifter^7];
          dataU9[0]<=qpiCommand[shifter^7];
          shifter<=shifter+1;        
        end    

        stateIdle: begin
          o_busy<=0;
          direction<=8'b0; // all 'Z', stay put
          action<=DONOTHING;

          if (i_cs==0) begin
            if (i_write==1) begin 
              action<=DOWRITE;
              qpiCommand<=SPIQuadWrite;
              byteToWrite<=i_dataToWrite;
            end
            else begin
              action<=DOREAD;
              qpiCommand<=SPIQuadRead;
            end
            bank<=i_bank;
            address<=i_address;
            shifter<=0;
            cntWaitCycles<=WAITCYCLES;
            o_busy<=1;
            o_dataReady<=0;
          end                      
        end

        sendQPIWriteCmd, 
        sendQPIReadCmd: begin          
          if (!bank) begin
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
          direction<=8'b00001111; // all pins active
          if (bank) direction<=8'b11110000; // all pins active
          case (shifter) 
            8:  if (!bank) dataU7[3:0]<=address[23:20];
                else dataU9[3:0]<=address[23:20];
            9:  if (!bank) dataU7[3:0]<=address[19:16];
                else dataU9[3:0]<=address[19:16];
            10: if (!bank) dataU7[3:0]<=address[15:12];
                else dataU9[3:0]<=address[15:12];      
            11: if (!bank) dataU7[3:0]<=address[11:8];
                else dataU9[3:0]<=address[11:8];
            12: if (!bank) dataU7[3:0]<=address[7:4];
                else dataU9[3:0]<=address[7:4];
            13: if (!bank) dataU7[3:0]<=address[3:0];
                else dataU9[3:0]<=address[3:0];
          endcase
          shifter<=shifter+1;        
        end

        /* We have to wait for the psram to fetch our data before we can
            actually read after having sent the address. */

        waitCycles: begin
          direction<=8'b00000000; // all pins Z
          if (cntWaitCycles>0) cntWaitCycles<=cntWaitCycles-1;
          shifter<=0;
        end

        writeData: begin
          direction<=8'b00001111; // all pins active
          if (bank) direction<=8'b11110000; // all pins active
          case (shifter) 
            14: if (!bank) dataU7[3:0]<=byteToWrite[7:4];
                else dataU9[3:0]<=byteToWrite[7:4];      
            15: begin
                  if (!bank) dataU7[3:0]<=byteToWrite[3:0];
                  else dataU9[3:0]<=byteToWrite[3:0];
                  action<=DONOTHING;
                end
          endcase
          shifter<=shifter+1;      
        end

        readData: begin
          if (shifter==0) begin
            if (!bank) begin
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
          else if (shifter==1) begin
            if (!bank) begin
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
            o_dataReady<=1;
            o_busy<=0;
          end          
          shifter<=shifter+1;               
        end
        
        default: ;        
      
      endcase
    end
  end
endmodule
 


  
  
