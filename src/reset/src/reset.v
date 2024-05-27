// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Germany, Herne

/*
    Reset functionality, will reset for 500ms after FPGA signals start or
    when the specified button is pushed.
*/
module reset(clk, fpga_but1, fpga_start, reset);
  
  input clk; // 10 Mhz std fpga clk
  input fpga_start; // FPGA reports it is starting (programming finished)
  input fpga_but1;
  output reset;

  // We will keep reset active for 500ms
  localparam [22:0] DELAY_500MS=23'h4c4b40;
  reg [22:0] counter=0;

  assign reset=!(counter<DELAY_500MS);

  always @(posedge clk, negedge fpga_but1 or posedge fpga_start) 
  begin
    if (!fpga_but1) counter<=0;
    else if (fpga_start) counter<=0;
    else if (counter<=DELAY_500MS) counter++;
  end
endmodule