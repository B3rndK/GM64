// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef RESET_H
`define RESET_H

/*
    Reset functionality, will reset for 500ms after FPGA signals start or
    when the specified button is pushed.
*/

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
             output reset);       // low active

  localparam [25:0] DELAY_500MS=25'h4c4b40;   // We will keep reset active for 500ms
  reg [25:0] counter;

  assign reset=!(counter<DELAY_500MS);   
  
  always @(posedge clk) 
  begin
    if (!fpga_but1) counter<=0;
    if (!fpgaStart) counter<=0;
    else begin
      if (counter<=DELAY_500MS) counter<=counter+1;
    end
  end
  
endmodule

`endif