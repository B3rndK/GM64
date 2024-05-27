// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`include "../syncGen/src/syncGen.v"
`include "../VIC6569/src/VIC6569.v"

module gm64(clk0, fpga_but1, o_hsync, o_vsync, o_red, o_green, o_blue);

  input clk0, fpga_but1;
  output o_hsync, o_vsync;
  output [3:0] o_red;
  output [3:0] o_green;
  output [3:0] o_blue;
  reg [8:0] counter=0;
  
  wire clk270, clk180, clk90, clkVid, usr_ref_out;
  wire usr_pll_lock_stdy, usr_pll_lock;
  /*
	wire start;
	CC_USR_RSTN usr_rstn_inst (
   	.USR_RSTN(start) // FPGA is configured and starts running
  );*/

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

  VIC6569 U1 (
    .clk(clkVid),
    .reset(!fpga_but1),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_red(o_red),
    .o_green(o_green),
    .o_blue(o_blue)
  );
  
  //assign o_red={o_red[0],o_red[1],o_red[2],o_red[3]};

  // assign rgb = {b,g,r};
  /*
  always @(posedge clk0, negedge fpga_but)
  begin
    if (fpga_but) counter=0;
    else counter++;
  end
  */
endmodule
