// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Germany, Herne

`ifndef VIC6569_H
`define VIC6569_H

/*
    MOS 6569, "VIC-II"
*/

module VIC6569(input clk, 
               input reset, 
               output o_hsync, 
               output o_vsync, 
               output [3:0] o_red, 
               output [3:0] o_green, 
               output [3:0] o_blue);

  reg [3:0] red;
  reg [3:0] green;
  reg [3:0] blue;
  
  wire display_on;
  wire [9:0] o_hpos;
  wire [9:0] o_vpos;

  syncGen sync_gen(
    .clk(clk),
    .reset(reset),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_display_on(display_on),
    .o_hpos(o_hpos),
    .o_vpos(o_vpos)
  );

  always @(posedge clk or posedge reset)
  begin
    if (reset) begin
      red=0;
      green=0;       
      blue=0;       
    end 
    else begin
      if (o_vpos>=0 && o_vpos<556) begin
        red=o_vpos % 15;
        green=o_vpos % 15;       
        blue=o_vpos % 15;       
      end
      else if (o_vpos>=0) begin
        red=o_vpos % 15;
        green=0;       
        blue=0;       
      end
    end
  end

  assign  o_red = display_on ? red : 0;
  assign  o_green = display_on ? green : 0;
  assign  o_blue = display_on ? blue  : 0;
  
endmodule

`endif