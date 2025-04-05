// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`timescale 10us / 1us

module visuMon_tb();
  
logic clk;
logic reset;
logic cs;
debugInfo_t _debugInfo;

/* verilator lint_off UNUSEDSIGNAL */
logic hsync,vsync;
logic [3:0] red, green, blue;

/* verilator lint_off PINMISSING */
visuMon U1 (
  .i_clk25Mhz(clk), 
  .i_reset(reset), 
  .i_cs(cs),
  .i_debugInfo(_debugInfo),
  .o_hsync (hsync), 
  .o_vsync (vsync), 
  .o_red (red), 
  .o_green (green), 
  .o_blue (blue)
); 

initial begin
#1        cs=1;
          reset=1;
          clk = 1'b0;
          forever begin
#1          clk=~clk;  
          end
end

Color _color;
initial begin
          // $sdf_annotate("visuMon_tb.sdf", U1);
          //$dumpoff; $dumpon;
          $dumpfile("visuMon_tb.vcd");
          $dumpvars(0, visuMon_tb);
#2        $display("Start (Reset)");          
          reset=0;
#20       reset=1;
          $display ("Reset removed.");
#2        cs=0;
          _debugInfo.ledNo=1;
          _debugInfo.color=Red;
          _debugInfo.status=1;   
#2        cs=1;
#2        cs=0;
          _debugInfo.ledNo=2;
          _debugInfo.color=Green;
          _debugInfo.status=1;   
#2        cs=1;
#2        cs=0;   
          _debugInfo.ledNo=3;
          _debugInfo.color=Blue;
          _debugInfo.status=1;   
#2        cs=1;
#2        _debugInfo=U1.arrDebugInfo[1][18:0];
          assert(_debugInfo.ledNo==1);
          assert(_debugInfo.color==Red);
          assert(_debugInfo.status==1);
#2        _debugInfo=U1.arrDebugInfo[2][18:0];
          assert(_debugInfo.ledNo==2);
          assert(_debugInfo.color==Green);
          assert(_debugInfo.status==1);
#2        _debugInfo=U1.arrDebugInfo[3][18:0];
          assert(_debugInfo.ledNo==3);
          assert(_debugInfo.color==Blue);
          assert(_debugInfo.status==1);
          // Next is to wait for X=30, Y=11 which is ~11*640+30=7100 (maxX=9'd799, ~9'x31f) 11*7100
#78130    assert(U1.o_hpos==30);
          assert(U1.o_vpos==11);
          assert(U1.o_hsync==0);
          assert(U1.o_vsync==0);
          assert(U1.o_red==4'b0000);
          assert(U1.o_green==4'b0000);
          assert(U1.o_blue==4'b0000);
#2        $display("Finished: time=%3d, clk=%b",$time, clk); 
          $finish(0);
end

endmodule
