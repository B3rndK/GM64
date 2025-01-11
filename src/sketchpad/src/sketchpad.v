// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef SKETCHPAD_H
`define SKETCHPAD_H

/*
    Some small stuff for checking/testing if my understanding is right
*/
module sketchpad(input  clk,          
                 input  fpga_but1,    // FPGA Button
                 output wire signal); // low when signalled

  logic pressed;
  assign signal=pressed;
    
  always @(negedge clk) 
  begin
    if (!fpga_but1) pressed=1;
    else pressed=0;
  end
endmodule

`endif