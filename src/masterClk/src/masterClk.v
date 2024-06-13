// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef MASTERCLK_H
`define MASTERCLK_H

/* Master clock generation for video and RAM and ... */

module masterClk(input  clk10Mhz,
                 output clkRAM,
                 output clkVideo);

  parameter referenceClk="10.0"; // Reference clock is 10Mhz
  wire clk270, clk180, clk90, usr_ref_out;
  wire usr_pll_lock_stdy, usr_pll_lock;

	CC_PLL #(
		.REF_CLK(referenceClk),    // reference input in MHz
		.OUT_CLK("24.8"),   // pll output frequency in MHz
		.PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
		.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
		.CI_FILTER_CONST(2), // optional CI filter constant
		.CP_FILTER_CONST(4)  // optional CP filter constant
  ) pll_instVideo (
		.CLK_REF(clk10Mhz), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
		.USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(usr_pll_lock),
		.CLK270(clk270), .CLK180(clk180), .CLK90(clk90), .CLK0(clkVideo), .CLK_REF_OUT(usr_ref_out)
	);

	CC_PLL #(
		.REF_CLK(referenceClk),    // reference input in MHz
		.OUT_CLK("33.0"),   // pll output frequency in MHz
		.PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
		.LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
		.CI_FILTER_CONST(2), // optional CI filter constant
		.CP_FILTER_CONST(4)  // optional CP filter constant
	) pll_instRAM (
		.CLK_REF(clk10Mhz), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
		.USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(usr_pll_lock),
		.CLK270(clk270), .CLK180(clk180), .CLK90(clk90), .CLK0(clkRAM), .CLK_REF_OUT(usr_ref_out)
	);

endmodule

`endif

