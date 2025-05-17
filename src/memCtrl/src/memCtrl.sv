// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

`timescale 1us / 1ns
`include "memCtrl.vh"

/* 24-bit address, 8-Bit memory controller interface using 2x LY68S3200 
   32M (4Mx8) Bits Serial Pseudo-SRAM with QPI divided into 2 banks. */

module memCtrl( input logic i_clkRAM,  // RAM clock (100Mhz)
                input logic reset,
                input logic i_cs,    // 0-enable
                input logic i_write, // 0-read, 1-write
                input logic [23:0] i_address, // 24-bit address
                input logic i_bank, // 0- U7, 1- U9
                output logic o_psram_sclk,                
                input  logic [7:0] i_dataToWrite,
                output logic [7:0] o_dataRead,
                inout  wire [7:0] io_psram_data,
                output logic o_psram_cs,
                output logic o_busy, // 1-Busy
                output logic o_dataReady,
                output logic led); // 1-ready

  parameter initDelayInClkCyles=7500; // 150us @ 100Mhz+some bonus
  localparam logic[3:0] WAITCYCLES=6;
  logic [3:0] dataU7; // Bank 0
  logic [3:0] dataU9; // Bank 1
  logic [7:0] qpiCommand;
  
  Action action;
  logic stopClock;
   
  
  logic[3:0] cntWaitCycles;
  logic [23:0] address;
  logic bank;
  logic [15:0] delayCounter;
  StateMachine state, next;
   
  logic [7:0] byteToWrite;
  logic psram_cs;
  
  logic [5:0] shifter;
 
  assign o_psram_sclk= stopClock ? 0 : i_clkRAM;

  // Direction direction; // 0- in (read), 1-out (write)
  logic [7:0] direction;
  assign o_psram_cs= psram_cs;
  
  genvar i;
  generate
    for (i = 0; i<4 ; i++) begin
        assign io_psram_data[i] = direction[i] ? dataU7[i] : 1'bZ;
        assign io_psram_data[i+4] = direction[i+4] ? dataU9[i] : 1'bZ;        
    end
  endgenerate

  always_ff @(posedge i_clkRAM) 
    if (!reset) state<=stateXXX;
    else state<=next;  

  // PSRAM needs pulling down CS on falling edge to really be stable
  always_ff @(negedge i_clkRAM) begin
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
  end

  // next logic
  always_comb begin
    case (state)
      stateXXX:               next=stateReset;
            
      stateReset:             next=delayAfterReset;

      delayAfterReset:
        if (delayCounter==0)  next=sendQPIEnable;
        else                  next=delayAfterReset;        
  
      sendQPIEnable:      
      if (shifter==8)         next=stateIdle;
      else                    next=sendQPIEnable;
  
      stateIdle: begin
        case (action)
          DONOTHING:          next=stateIdle;
          DOWRITE:            next=sendQPIWriteCmd;
          DOREAD:             next=sendQPIReadCmd;
          default:            next=stateIdle;
        endcase
      end
      
      sendQPIWriteCmd:
        if (shifter==8)       next=sendQPIAddress;
        else                  next=sendQPIWriteCmd;
      
      sendQPIReadCmd:
        if (shifter==8)       next=sendQPIAddress;
        else                  next=sendQPIReadCmd;

      sendQPIAddress:
        if (shifter==14) begin
          if (action==DOWRITE)  next=writeData;
          else                  next=waitCycles; 
        end
        else                    next=sendQPIAddress;

      waitCycles:
        if (cntWaitCycles==0)   next=readData;
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
    case (next) 

      stateReset: begin
        o_busy<=1;
        direction<=8'hff;
        dataU7='b0;
        dataU9='b0;       
        delayCounter<=initDelayInClkCyles;
        stopClock<=1;
        shifter<=0;
        o_dataReady<=0;
        o_dataRead<=8'h00;
      end

      delayAfterReset: begin 
        delayCounter<=delayCounter-1;
        if (delayCounter==3) begin
          stopClock<=0;
          qpiCommand<=enableQPIModeCmd;
          led<=0;
        end
      end

      sendQPIEnable: begin
        direction<=8'b00010001; // SI active only on both chips
        dataU7[0]<=qpiCommand[shifter^7];
        dataU9[0]<=qpiCommand[shifter^7];
        shifter<=shifter+1;        
      end    

      stateIdle: begin
        action<=DONOTHING;
        o_busy<=0;
        direction<=8'b0; // all 'Z', stay put

        if (i_cs==0) begin
          o_dataReady<=0;
          bank<=i_bank;
          address<=i_address;
          shifter<=0;
          o_busy<=1;
          if (i_write) begin 
            action<=DOWRITE;
            qpiCommand<=SPIQuadWrite;
            byteToWrite<=i_dataToWrite;
          end
          else begin
            action<=DOREAD;
            cntWaitCycles<=WAITCYCLES;
            qpiCommand<=SPIQuadRead;
          end
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
        if (!bank) begin
          direction<=8'b00001111; // all pins active
          case (shifter) 
            8:  dataU7[3:0]<=address[23:20];
            9:  dataU7[3:0]<=address[19:16];
            10: dataU7[3:0]<=address[15:12];
            11: dataU7[3:0]<=address[11:8];
            12: dataU7[3:0]<=address[7:4];
            13: dataU7[3:0]<=address[3:0];
          endcase
        end
        else begin
          direction<=8'b11110000; // all pins active
          case (shifter) 
            8:  dataU9[3:0]<=address[23:20];
            9:  dataU9[3:0]<=address[19:16];
            10: dataU9[3:0]<=address[15:12];
            11: dataU9[3:0]<=address[11:8];
            12: dataU9[3:0]<=address[7:4];
            13: dataU9[3:0]<=address[3:0];
          endcase
        end
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

          15: if (!bank) dataU7[3:0]<=byteToWrite[3:0];
              else dataU9[3:0]<=byteToWrite[3:0];
        endcase
        shifter<=shifter+1;      
      end

      readData: begin
        shifter<=shifter+1;
        case (shifter) 
          0: 
            if (bank==0) o_dataRead[7:4]=io_psram_data[3:0];
            else o_dataRead[7:4]=io_psram_data[7:4];
          1: begin 
              if (bank==0) o_dataRead[3:0]=io_psram_data[3:0];
              else o_dataRead[3:0]=io_psram_data[7:4];
            end
          2: begin
              o_busy<=0;
              o_dataReady<=1;
            end
        endcase
      end
    endcase 
  end
endmodule
 


  
  
