// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef GM64_H
`define GM64_H

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

  wire clk270, clk180, clk90, clkVid, usr_ref_out;
  wire usr_pll_lock_stdy, usr_pll_lock;
  
  CC_USR_RSTN usr_rstn_inst (
   	.USR_RSTN(fpga_start) // FPGA is configured and starts running
  );
    
	CC_PLL #(
		.REF_CLK("10.0"),    // reference input in MHz
		.OUT_CLK("24.8"),   // pll output frequency in MHz
		.PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
		.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
		.CI_FILTER_CONST(2), // optional CI filter constant
		.CP_FILTER_CONST(4)  // optional CP filter constant
	) pll_inst (
		.CLK_REF(clk0), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
		.USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(usr_pll_lock),
		.CLK270(clk270), .CLK180(clk180), .CLK90(clk90), .CLK0(clkVid), .CLK_REF_OUT(usr_ref_out)
	);

  reset U2 (.clk(clk0), .fpga_but1(fpga_but1), .fpga_start(fpga_start), .reset(reset));  

  VIC6569 U1 (
    .clk(clkVid),
    .reset(!reset),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_red(o_red),
    .o_green(o_green),
    .o_blue(o_blue)
  );

endmodule  

`endif