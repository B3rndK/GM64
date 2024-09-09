// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef CLOCKGEN_H
`define CLOCKGEN_H

/* Main clock generation... */

module clockGen(input  clk10Mhz,
								output reg clkRAM,				
								output reg clkDot,
								output reg clkVideo,
								input  reset);
								
parameter dotClkPal="7.8";  //  7.881984 Mhz, most demos and nearly all games only run on PAL
parameter videoFrequency="24.8"; // 24.8Mhz for quirk 50Hz HDMI graphics mode 
parameter referenceClk="10.0"; 	 // Reference clock is 10Mhz coming from FPGA

reg usr_pll_lock_stdy_ram, usr_pll_lock_ram;
reg usr_pll_lock_stdy_video, usr_pll_lock_video;
reg usr_pll_lock_stdy_dot, usr_pll_lock_video_dot;
reg usr_pll_lock_dot;
reg clkDotOut, clkVideoOut, clkRAMOut;

CC_PLL #(
	.REF_CLK(referenceClk),    // reference input in MHz
	.OUT_CLK(dotClkPal),   // pll output frequency in MHz
	.PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
	.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
	.CLK270_DOUB(0),
	.CLK180_DOUB(0),
	.CI_FILTER_CONST(2), // optional CI filter constant
	.CP_FILTER_CONST(4) // optional CP filter constant	
) pll_inst_clkdot (
	.CLK_REF(clk10Mhz), .CLK_FEEDBACK(1'b0),
	.USR_LOCKED_STDY_RST(reset), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy_dot), .USR_PLL_LOCKED(usr_pll_lock_dot),
	.CLK0(clkDotOut)
);

// Connect the new clk to the global routing resources to ensure that all
// modules get the signal (nearly...) at the same time
CC_BUFG pll_clkdot (.I(clkDotOut), .O(clkDot));

CC_PLL #(
	.REF_CLK(referenceClk),    // reference input in MHz
	.OUT_CLK(videoFrequency),   // pll output frequency in MHz
	.PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
	.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
	.CLK270_DOUB(0),
	.CLK180_DOUB(0),
	.CI_FILTER_CONST(2), // optional CI filter constant
	.CP_FILTER_CONST(4) // optional CP filter constant		
) pll_inst_clkvideo (
	.CLK_REF(clk10Mhz), .CLK_FEEDBACK(1'b0), 
	.USR_LOCKED_STDY_RST(reset), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy_video), .USR_PLL_LOCKED(usr_pll_lock_video),
	.CLK0(clkVideoOut)
);

// Connect the new clk to the global routing resources to ensure that all
// modules get the signal (nearly...) at the same time
CC_BUFG pll_clkVideo (.I(clkVideoOut), .O(clkVideo));

CC_PLL #(
	.REF_CLK(referenceClk),    // reference input in MHz
	.OUT_CLK("100.0"),   // pll output frequency in MHz
	.PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
	.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
	.CLK270_DOUB(0),
	.CLK180_DOUB(0),
	.CI_FILTER_CONST(2), // optional CI filter constant
	.CP_FILTER_CONST(4) // optional CP filter constant		
) pll_inst_ram (
	.CLK_REF(clk10Mhz), .CLK_FEEDBACK(1'b0),
	.USR_LOCKED_STDY_RST(reset), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy_ram), .USR_PLL_LOCKED(usr_pll_lock_ram),
	.CLK0(clkRAMOut)
);

// Connect the new clk to the global routing resources to ensure that all
// modules get the signal (nearly...) at the same time
CC_BUFG pll_clkRAM (.I(clkRAMOut), .O(clkRAM));

endmodule

`endif


