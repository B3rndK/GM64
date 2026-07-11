// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`timescale 1ns / 1ns

module gm64_tb();

  reg clk;
  logic fpga_start;
  reg  reset;
  reg fpga_but1=1;

  logic csVisuMon;
  logic o_hsync, o_vsync;
  logic[3:0] o_red,o_green,o_blue;
  logic o_led;

initial begin
  clk = 1'b0;
  csVisuMon=1;
  forever #1 clk = ~clk;
end  

initial begin
          //$sdf_annotate("reset_tb.sdf", U1);
          $dumpon;
          $dumpfile("sim/gm64_tb.fst");
          $dumpvars(0, gm64_tb);
          $display("Start: time=%3d, clk=%b, reset=%b",$time, clk, reset);
#9000000  assert(0==0);
#1000000  $display("Finished. time=%3d, clk=%b, reset=%b",$time, clk, reset);
          $finish(0);
end
endmodule;