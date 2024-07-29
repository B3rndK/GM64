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

typedef enum {
  enableQPIMode=8'h35
} QPICommands;

module memCtrl( input            clk,
                input            reset,
                input            CE,    // 1-enable, 0-Z 
                input            write, // 0-read, 1-write
                input reg [15:0] addrBus,
                input reg [3:0]  numberOfBytesToWrite,
                input reg [15*7:0] dataToWrite,
                output reg [7:0]   dataRead,
                output o_psram_cs,
                output o_psram_sclk,
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

  parameter enableQPICmd=8'h35;

  wire SCLK;
  wire CS;

  reg [5:0] state;
  reg [5:0] nextState;

  reg [7:0] qpiCmd;

  assign busy=isBusy;
  assign o_psram_cs=memCtrlCE;
  assign o_psram_sclk=SCLK;

    
  always @(posedge clk or posedge reset)  // e.g. PHI0
  begin
    if (reset) begin
      nextState=stateReset;
    end
    else begin
      if (nextState==stateReset)  state=stateInit;
      else begin
        state=nextState;
        SCLK=~SCLK;
      end
    end
  end

  /* We will allow concurrent access on odd/even cycles later on
  always @(negedge clk or posedge reset) // e.g. VICII
  begin
    if (reset) begin
      nextState=stateReset;
    end
    else begin
      if (nextState==stateReset)  state=stateInit;
      else state=nextState;
    end
  end
  */

  always @* begin
    case (state)
      stateReset: begin
        isBusy=true;
        SCLK=LOW;
        memCtrlCE=HIGH;
      end

      stateInit: begin
        SCLK=HIGH;
        nextState=stateInit_2;
      end

      stateInit_2: begin
        SCLK=LOW;
        nextState=stateIdle;
      end

      stateIdle: begin
        isBusy=false;
        SCLK=~SCLK;
        if (CE) begin
          isBusy=true;
          address=addrBus;
          if (!write) begin
            nextState=stateRead_1;
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