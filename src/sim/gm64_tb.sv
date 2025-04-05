// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`timescale 1ns / 1ns

module gm64_tb();

  reg clk;
  logic fpga_start;
  reg  reset;
  reg fpga_but1=1;

  logic csVisuMon;
  debugInfo_t debugInfo;
  logic o_hsync, o_vsync;
  logic[3:0] o_red,o_green,o_blue;
  logic o_led;

visuMon U99 ( .i_clkVideo(clk),
              .i_reset(1),
              .i_cs(csVisuMon),    
              .i_debugInfo(debugInfo),
              .o_hsync(o_hsync), 
              .o_vsync(o_vsync), 
              .o_red(o_red), 
              .o_green(o_green), 
              .o_blue(o_blue),
              .o_led(o_led));


initial begin
  $asserton;
  clk = 1'b0;
  csVisuMon=1;
  debugInfo[17:0]=0;
  
  forever #1 clk = ~clk;

end  

initial begin
          //$sdf_annotate("reset_tb.sdf", U1);
          $dumpon;
          $dumpfile("sim/gm64_tb.fst");
          $dumpvars(0, gm64_tb);
          $display("Start: time=%3d, clk=%b, reset=%b",$time, clk, reset);
#1        debugInfo.ledNo=1;
          debugInfo.color=Magenta;
          debugInfo.status=1;
          csVisuMon=1;
#2        assert(U99.arrDebugInfo[1].ledNo==0);
#2        csVisuMon=0;
#2        csVisuMon=1;
#2        assert(U99.arrDebugInfo[1].ledNo==1);
          assert(U99.arrDebugInfo[1].status==1);
          assert(U99.arrDebugInfo[1].color==Magenta);
#100      debugInfo.ledNo=1;
          debugInfo.color=Black;
          debugInfo.status=0;
#2        csVisuMon=0;
#100      debugInfo.ledNo=1;
          debugInfo.color=Green;
          debugInfo.status=0;
#200      assert(U99.arrDebugInfo[1].ledNo==1);
          assert(U99.arrDebugInfo[1].status==0);
          assert(U99.arrDebugInfo[1].color==Black);
#2        csVisuMon=1;
#2        csVisuMon=0;
#2        assert(U99.arrDebugInfo[1].ledNo==1);
          assert(U99.arrDebugInfo[1].status==0);
          assert(U99.arrDebugInfo[1].color==Green);
#2        csVisuMon=1;

#9000000  assert(reset==0);
#1000000  $display("Finished. time=%3d, clk=%b, reset=%b",$time, clk, reset);
          $finish(0);
end
endmodule;