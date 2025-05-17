// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef CLOCKGEN_H
`define CLOCKGEN_H

/* verilator lint_off TIMESCALEMOD */

/* Main clock generation... */

module clockGen(input wire clk10Mhz,
   				output logic clk100Mhz);
								
parameter sysclk=75; // We need at least 48 Mhz for the 'PSRAM race'...sysclk/50 will provide us 0.9582 (PAL) phi
parameter referenceClk=10; 	 // Reference clock is 10Mhz coming from FPGA
// wire clkSysPLL;
wire usr_pll_lock_stdy, usr_pll_lock;

CC_PLL #(
	.REF_CLK(referenceClk), 		// reference input in MHz
	.OUT_CLK(sysclk),   	// pll output frequency in MHz
	.LOCK_REQ(1),
	.LOW_JITTER(1),    			// 0: disable, 1: enable low jitter mode
	.PERF_MD("SPEED") 	// LOWPOWER, ECONOMY, SPEED	
	) pll_inst (
	.CLK_REF(clk10Mhz), .USR_PLL_LOCKED(usr_pll_lock),	
	.USR_CLK_REF(),
	.CLK_FEEDBACK(),
	.USR_LOCKED_STDY_RST(),
	.USR_PLL_LOCKED_STDY(),
	.CLK0(clk100Mhz),
	.CLK90(),
	.CLK180(),
	.CLK270(),
	.CLK_REF_OUT()	
);

//wire pll_clk_nobuf;
// CC_BUFG pll_bufg (.I(pll_clk_nobuf), .O(clkSys));


// Connect the sysclk to the global routing resources of the FPGA to ensure that all
// modules get the signal (nearly...) at the same time
// CC_BUFG pll_sysclk (.I(clkSysPLL), .O(clkSys));

endmodule

`endif


