// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Germany, Herne

`ifndef VIC6569_H
`define VIC6569_H

/*
    MOS 6569, "VIC-II"
*/

module VIC6569(input clk,
               input clkDot, 
               input reset, 
               output clkPhi0,
               output o_hsync, 
               output o_vsync, 
               output [3:0] o_red, 
               output [3:0] o_green, 
               output [3:0] o_blue,
               input [3:0] debugValue);
               

  reg [3:0] red;
  reg [3:0] green;
  reg [3:0] blue;
  
  wire display_on;
  wire [9:0] o_hpos;
  wire [9:0] o_vpos;

  // Creating Phi0 clock for CPU by dividing clkDot by 
  reg [4:0] cntPhi0;
  assign clkPhi0=cntPhi0>7;

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
      case (debugValue)
        4'b0000 : begin red=0; green=0; blue=0; end
        4'b0001 : begin red=15;green=0;blue=0; end
        4'b0010 : begin red=0;green=15;blue=0; end
        4'b0011 : begin red=15;green=15;blue=0; end
        4'b0100 : begin red=0;green=15;blue=15; end
        4'b0101 : begin red=0;green=0;blue=15; end
        default : begin red=15;green=15;blue=15; end
      endcase
      /*
      if (o_vpos>=0 && o_vpos<556) begin
        red=o_vpos % 15;
        green=o_vpos % 15;       
        blue=o_vpos % 15;       
      end
      else if (o_vpos>=0) begin
        red=o_vpos % 15;
        green=0;       
        blue=0;       
      end*/

    end
  end

  assign  o_red = (display_on) ? red : 0;
  assign  o_green = (display_on) ? green : 0;
  assign  o_blue = (display_on) ? blue  : 0;

  // The VIC-II generates the CPU clk (phi0) by dividing the clkDot by 8.
  always @(posedge clkDot or posedge reset)
  begin
    if (reset) begin
      cntPhi0=0;
    end 
    else begin
      cntPhi0++;
      if (cntPhi0>16) begin
        cntPhi0=0;
      end
    end
  end
endmodule

`endif