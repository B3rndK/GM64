// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef CLOCKGEN_H
`define CLOCKGEN_H

/* Main clock generation... */

module clockGen(input  clk10Mhz,
								output clkRAM,				
								output clkDot,
								output clkVideo,
								input  reset);
								
parameter dotClkPal="7.8";  //  7.881984 Mhz, most demos and nearly all games only run on PAL
parameter videoFrequency="24.8"; // 24.8Mhz for quirk 50Hz HDMI graphics mode 
parameter referenceClk="10.0"; 	 // Reference clock is 10Mhz coming from FPGA

reg resetDetected;
reg usr_pll_lock_stdy_ram, usr_pll_lock_ram;
reg usr_pll_lock_stdy_video, usr_pll_lock_video;
reg usr_pll_lock_stdy_dot, usr_pll_lock_video_dot;
reg usr_pll_lock_dot;

CC_PLL #(
	.REF_CLK(referenceClk),    // reference input in MHz
	.OUT_CLK(dotClkPal),   // pll output frequency in MHz
	.PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
	.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
) pll_inst_clkdot (
	.CLK_REF(clk10Mhz), .CLK_FEEDBACK(1'b0),
	.USR_LOCKED_STDY_RST(resetDetected), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy_dot), .USR_PLL_LOCKED(usr_pll_lock_dot),
	.CLK0(clkDot)
);

CC_PLL #(
	.REF_CLK(referenceClk),    // reference input in MHz
	.OUT_CLK(videoFrequency),   // pll output frequency in MHz
	.PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
	.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
) pll_inst_clkvideo (
	.CLK_REF(clk10Mhz), .CLK_FEEDBACK(1'b0), 
	.USR_LOCKED_STDY_RST(resetDetected), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy_video), .USR_PLL_LOCKED(usr_pll_lock_video),
	.CLK0(clkVideo)
);

CC_PLL #(
	.REF_CLK(referenceClk),    // reference input in MHz
	.OUT_CLK("100.0"),   // pll output frequency in MHz
	.PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
	.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
) pll_inst_ram (
	.CLK_REF(clk10Mhz), .CLK_FEEDBACK(1'b0),
	.USR_LOCKED_STDY_RST(resetDetected), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy_ram), .USR_PLL_LOCKED(usr_pll_lock_ram),
	.CLK0(clkRAM)
);
/*
	always @(posedge clk10Mhz, negedge reset)
	begin
		if (reset) begin
			resetDetected=1;
		end
		else resetDetected=0;
	end;
*/
endmodule

`endif


