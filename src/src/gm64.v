// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef GM64_H
`define GM64_H

`include "../masterClk/src/masterClk.v"
`include "../syncGen/src/syncGen.v"
`include "../VIC6569/src/VIC6569.v"
`include "../reset/src/reset.v"

module gm64(input clk0, 
            input reset, 
            input fpga_but1, 
            output o_hsync, 
            output o_vsync, 
            output [3:0] o_red, 
            output [3:0] o_green, 
            output [3:0] o_blue);

  wire clkVideo, clkRAM;
 
  CC_USR_RSTN usr_rstn_inst (
   	.USR_RSTN(fpga_start) // FPGA is configured and starts running
  );

  reset U1 (.clk(clk0), .fpga_but1(fpga_but1), .fpga_start(fpga_start), .reset(reset));  
  masterClk U2(.clk10Mhz(clk0),.clkRAM(clkRAM),.clkVideo(clkVideo));

  VIC6569 U3 (
    .clk(clkVideo),
    .reset(!reset),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_red(o_red),
    .o_green(o_green),
    .o_blue(o_blue)
  );

endmodule  

`endif