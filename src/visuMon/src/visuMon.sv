// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

`ifndef VISUMON_H
`define VISUMON_H

`include "./syncGen/src/syncGen.v"
`include "visuMon.svh"

/* Tool to simulate 64 LEDs using a simple VGA monitor display. 
   When we have VGA, why use LEDs? ;-)  */

module visuMon( input   logic i_clk25Mhz,
                input   logic i_reset,
                input   logic i_cs,    
                input   debugInfo_t i_debugInfo,
                output  o_hsync, 
                output  o_vsync, 
                output  [3:0] o_red, 
                output  [3:0] o_green, 
                output  [3:0] o_blue,
                output  o_led);

debugInfo_t arrDebugInfo[63];

debugInfo_t debugInfoTemp;

logic [3:0] _red;
logic [3:0] _green;
logic [3:0] _blue;
  
logic _display_on;
logic [9:0] o_hpos;
logic [9:0] o_vpos;

assign  o_red = _display_on ? _red : 4'b0000;
assign  o_green = _display_on ? _green : 4'b0000;
assign  o_blue = _display_on ? _blue  : 4'b0000;

logic led;
assign o_led=!led;

syncGen sync_gen(
    .clk(i_clk25Mhz),
    .reset(i_reset),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_display_on(_display_on),
    .o_hpos(o_hpos),
    .o_vpos(o_vpos)
);

always @(posedge i_clk25Mhz)
begin
  if (!i_cs) begin 
    arrDebugInfo[0][18:0]<=i_debugInfo;
  end
end
  
always_ff @(posedge i_clk25Mhz or negedge i_reset)
begin
  if (!i_reset) begin
    _red<=0;
    _green<=0;       
    _blue<=0;       
  end 
  else begin
    if (o_vpos<=40 || o_vpos>440) begin
      debugInfoTemp<=arrDebugInfo[0][18:0];
      _red<=debugInfoTemp.color[11:8];
      _green<=debugInfoTemp.color[7:4];       
      _blue<=debugInfoTemp.color[3:0];  
    end
    else begin
      _red<=0;
      _green<=0;       
      _blue<=0;       
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


  
  
 

  
  
