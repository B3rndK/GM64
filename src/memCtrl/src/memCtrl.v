// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef MEMCTRL_H
`define MEMCTRL_H

/* Memory controller interface
   Supports concurrent access by clk that is, clock low = channel 1, 
   clock high= channel 2*/

typedef enum {
  stateReset=0,
  stateInit_1=1,
  stateInit_2=2,
  stateEnableQPI=3,
  stateIdle=4,
  stateRead_1=5
} StateMachine;

typedef enum bit[7:0] {
  enableQPIMode=8'h35
} QPICommands;

module memCtrl( input            clk,
                input            reset,
                input            CE,    // 1-enable, 0-Z 
                input            write, // 0-read, 1-write
                input reg [6:0]  bank, // bank 0-63 forming a total of 4096KB
                input reg [15:0] addrBus,
                input reg [3:0]  numberOfBytesToWrite,
                input reg [15*7:0] dataToWrite,
                output reg [7:0]   dataRead,
                inout  wire io_psram_data0,
                inout  wire io_psram_data1,
                inout  wire io_psram_data2,
                inout  wire io_psram_data3,
                inout  wire io_psram_data4,
                inout  wire io_psram_data5,
                inout  wire io_psram_data6,
                inout  wire io_psram_data7,            
                output o_psram_cs,
                output o_psram_sclk,
                output busy); // 1-busy
  
   
  reg isBusy;

  reg [15:0] address;
  
  parameter LOW=1'b0;
  parameter HIGH=1'b1;
 
  parameter initDelayInClkCyles=15000; // 150us @100Mhz
  shortint delayCounter;
 
  wire CS;

  reg [5:0] state;
  reg [5:0] nextState;

  reg [7:0] qpiCmd;

  reg memCtrlCE;
  
  assign busy=isBusy;
  reg psram_cs;
  assign o_psram_cs=psram_cs;

  reg dataU7[3:0];
  reg dataU9[3:0];
  reg psram_sclk;

  assign o_psram_sclk=clk;
  
  always @(clk)
  begin
    if (delayCounter>0) delayCounter--;
  end

  always @(posedge clk or posedge reset)  // e.g. PHI0
  begin
    if (reset) begin
      state=stateReset;
      delayCounter=initDelayInClkCyles;
    end
    else begin
      ;
    end
  end

  /* We will allow concurrent access on odd/even cycles later on */

  always @(negedge clk or posedge reset) // e.g. VICII
  begin
    if (reset) begin
      ;
    end
    else begin
      ;
    end
  end
  
  always @(posedge clk) begin
    case (state)
      stateReset: begin
        // Initialization, should be kept low for 150us (10ns per clock~ 150*1000/10 clks)
        psram_cs=HIGH;
        isBusy=1;
        
        // U7
        dataU7[0]=LOW;
        dataU7[1]=LOW;
        dataU7[2]=LOW;
        dataU7[3]=LOW;
        
        // U9
        dataU9[0]=LOW;
        dataU9[1]=LOW;
        dataU9[2]=LOW;
        dataU9[3]=LOW;
       
        state=stateInit_1;
      end

      stateInit_1: begin
        if (delayCounter<=0) begin
          state=stateInit_2;
        end
      end

      stateInit_2: begin
        state=stateIdle;
      end

      stateIdle: begin
        isBusy=0;
        if (CE) begin
          isBusy=1;
          address=addrBus;
          if (!write) begin
            state=stateRead_1;
          end
        end
      end
      
      stateRead_1: begin
        qpiCmd=enableQPIMode;
        //io_psram_data0
      end

      default:
        nextState=reset;
    endcase
  end


endmodule

`endif