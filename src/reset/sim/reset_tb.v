// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`timescale 1ns / 1ns

module reset_tb ();
 
  reg clk;
  reg fpga_start;
  reg  reset;
  reg fpga_but1=1;

reset U1 (.clk (clk), .fpga_but1 (fpga_but1), .fpga_start(fpga_start), .reset(reset));

initial begin
  clk = 1'b0;
  forever #1 clk = ~clk;
end  

initial begin
          // $sdf_annotate("reset_tb.sdf", U1);
          // $dumpoff; $dumpon;

          $dumpfile("sim/reset_tb.vcd");
          $dumpvars(0, reset_tb);
#1        $display("Reset on restart fpga: time=%3d, clk=%b, reset=%b",$time, clk, reset);
#1        fpga_start=1;
#10       fpga_start=0;
          assert(reset==0);
#1
#9999999  $display("Finished. time=%3d, clk=%b, reset=%b",$time, clk, reset);
          assert(reset==1);
#100
          fpga_but1=0;
#1        $display("Reset on button pressed: time=%3d, clk=%b, reset=%b",$time, clk, reset);
#10       fpga_but1=1;
#1        assert(reset==0);
#9000000  assert(reset==0);
#1000000  $display("Finished. time=%3d, clk=%b, reset=%b",$time, clk, reset);
#1        assert(reset==1);
          $finish(0);
end

endmodule;