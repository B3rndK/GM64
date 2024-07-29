// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef RESET_H
`define RESET_H

/*
    Reset functionality, will reset for 500ms after FPGA signals start or
    when the specified button is pushed.
*/
module reset(input  clk,          // 10 Mhz std fpga clk
             input  fpga_but1,    // FPGA Button
             input  fpgaStart,    // FPGA reports it is starting (programming finished)
             output reset);       // low active

  localparam [25:0] DELAY_500MS=25'h4c4b40;   // We will keep reset active for 500ms
  reg [25:0] counter=DELAY_500MS+1;
   
  always @(posedge clk, negedge fpga_but1 or negedge fpgaStart) 
  begin
    if (!fpga_but1) counter<=0;
    else if (!fpgaStart) counter<=0;
    else begin
      if (counter<=DELAY_500MS) counter++;
    end
  end

  assign reset=!(counter<DELAY_500MS);

endmodule

`endif