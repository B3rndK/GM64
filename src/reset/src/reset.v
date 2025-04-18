// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef RESET_H
`define RESET_H

/*
    Reset functionality, will reset for 500ms after FPGA signals start or
    when the specified button is pushed.
*/
/* verilator lint_off TIMESCALEMOD */

// assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
// wire [1:0] ar = status[13:12];
/*
always @(posedge clk_sys) begin
	reg old_toggle = 0;
	reg old_pal_toggle = 0;

	old_toggle <= video_toggle;
	old_pal_toggle <= palette_toggle;

	// display change request from keyboard
	if (video_toggle != old_toggle) begin
		screen_mode_req = screen_mode + 1'b1;
	end 
  */

module reset(input  clk,          // 10 Mhz std fpga clk
             input  fpga_but1,    // FPGA Button
             input  fpgaStart,    // FPGA reports it is starting (programming finished)
             output logic reset); // low active

  localparam [25:0] DELAY_100MS='d50000;   // We will keep reset active for 50ms
  int counter;

  always @(posedge clk) 
  begin
    if (fpga_but1===0) counter=0;
    if (fpgaStart===1) begin
      if (counter<DELAY_100MS) counter=counter+1;
      reset=!(counter<DELAY_100MS);
    end
  end
  
endmodule

`endif