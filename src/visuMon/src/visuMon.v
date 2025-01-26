// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

`ifndef VISUMON_H
`define VISUMON_H

`include "./syncGen/src/syncGen.v"
`include "visuMon.vh"

/* Tool to simulate 64 LEDs using a simple VGA monitor display. 
   When we have VGA, why use LEDs? ;-)  */

module visuMon( input   logic i_clk25Mhz,
                input   logic i_reset,
                input   logic i_cs,    
                input   debugInfo i_debugInfo,
                output  o_hsync, 
                output  o_vsync, 
                output  [3:0] o_red, 
                output  [3:0] o_green, 
                output  [3:0] o_blue); 


debugInfo [0:63] _debugInfo;

logic [3:0] _red;
logic [3:0] _green;
logic [3:0] _blue;
  
logic _display_on;
logic [9:0] o_hpos;
logic [9:0] o_vpos;

assign  o_red = _display_on ? _red : 0;
assign  o_green = _display_on ? _green : 0;
assign  o_blue = _display_on ? _blue  : 0;

syncGen sync_gen(
    .clk(i_clk25Mhz),
    .reset(i_reset),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_display_on(_display_on),
    .o_hpos(o_hpos),
    .o_vpos(o_vpos)
  );

  always @(posedge i_clk25Mhz or negedge i_reset)
  begin
    if (!i_reset) begin
      _red<=0;
      _green<=0;       
      _blue<=0;       
    end 
    else begin

      if (o_vpos<=20 || o_vpos>470) begin
        _red<=4;
        _green<=8;       
        _blue<=15;       
      end

    end
  end


  /*  Berni's template...

  always_ff @(posedge i_clkRAM or negedge reset) 
    if (!reset) state<=stateXXX;
    else state<=next;  
  
  always_comb begin
    next=stateXXX;
    case (state)
      stateXXX:               next=stateReset;
      stateReset:             next=delayAfterReset;
      endcase
  end
  
  always_ff @(posedge i_clkRAM or negedge reset) begin
    if (!reset) begin
    end
    else begin

      case (next) 
        stateReset: begin
          ;
        end

        default: ;

      endcase
    end
  end */

endmodule
`endif 


  
  
