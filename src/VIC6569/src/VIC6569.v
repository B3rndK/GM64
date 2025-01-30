// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Germany, Herne

`ifndef VIC6569_H
`define VIC6569_H

/*
    MOS 6569, "VIC-II"
*/

module VIC6569(input clkSys,
               input logic reset, 
               output clkPhi0, // CPU
               output clkPhi2, // VIC (inverted phi0)
               output o_hsync, 
               output o_vsync, 
               output [3:0] o_red, 
               output [3:0] o_green, 
               output [3:0] o_blue,
               input reg [3:0] debugVIC);
               
  parameter CLK_PHI0_DIVIDER=25; 
  reg [3:0] red;
  reg [3:0] green;
  reg [3:0] blue;
  
  wire display_on;
  wire [9:0] o_hpos;
  wire [9:0] o_vpos;

  logic clkHDMI;

  // Creating Phi0 clock for CPU 
  reg [5:0] cntPhi0;
  reg [2:0] cntHDMI;
    
  assign clkPhi0=cntPhi0>=CLK_PHI0_DIVIDER;
  assign clkPhi2=~cntPhi0;
  assign clkHDMI=cntHDMI<2;

  assign  o_red =   display_on ? red : 4'b0000;
  assign  o_green = display_on ? green : 4'b0000;
  assign  o_blue =  display_on ? blue  : 4'b0000;

  syncGen sync_gen(
    .clk(clkHDMI),
    .reset(reset),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_display_on(display_on),
    .o_hpos(o_hpos),
    .o_vpos(o_vpos)
  );

  always @(posedge clkHDMI or negedge reset)
  begin
    if (!reset) begin
      red<=15;
      green<=15;       
      blue<=15;       
    end 
    else begin
      case (debugVIC)
        4'b0000 : begin red<=4; green<=4; blue<=12; end
        4'b0001 : begin red<=15;green<=0;blue<=0; end
        4'b0010 : begin red<=0;green<=15;blue<=0; end
        4'b0011 : begin red<=15;green<=15;blue<=0; end
        4'b0100 : begin red<=0;green<=15;blue<=15; end
        4'b0101 : begin red<=0;green<=0;blue<=15; end
        default : begin red<=15;green<=15;blue<=15; end
      endcase
      if (o_vpos<=20 || o_vpos>470) begin
        red<=4;
        green<=8;       
        blue<=15;       
      end
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

  // The VIC-II generates the CPU clk (phi0) 
  always @(posedge clkSys or negedge reset)
  begin
    if (!reset) begin
      cntPhi0<=1;
    end 
    else begin
      if (cntPhi0==50) begin
        cntPhi0<=1;
      end
      else cntPhi0<=cntPhi0+1;

    end
  end

  // We also need a video clock ~24.8Mhz for a quirk 50Hz HDMI graphics mode
  always @(posedge clkSys or negedge reset)
  begin
    if (!reset) begin
      cntHDMI<=1;
    end 
    else begin
      if (cntHDMI==2) begin
        cntHDMI<=1;
      end
      else cntHDMI<=cntHDMI+1;

    end
  end

endmodule

`endif