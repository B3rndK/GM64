// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`timescale 1us / 1us

module counter_tb();
  
reg clk;
reg reset;
reg irq;
reg cs;

reg[15:0] value;
CounterMode mode;

counter U100 (
  .i_clk(clk),
  .i_reset(reset), 
  .i_cs(cs),
  .i_mode(mode),
  .i_value(value),
  .o_irq(irq)
);

localparam[15:0] STARTVALUE = 3;

initial begin
#2  mode=SINGLE_SHOT;
    value=STARTVALUE;
    reset=1;
    cs=1;
    clk = 1'b0;
    forever begin
      #1 clk <= ~clk;  
    end
end

initial begin
        // $sdf_annotate("counter_tb.sdf", U1);
        // $dumpoff; $dumpon;
        $dumpfile("sim/counter_tb.vcd");
        $dumpvars(0, counter_tb);
#2      $display("Start counter test. time=%3d, clk=%b, reset=%b",$time, clk, reset);
        $display ("Reset low");
        reset=0;
#2      assert(U100.currentValue==0);
        assert(irq==0);
        $display("Mode=%d",U100.mode);
        reset=1;
        $display ("Reset high");        
#2      $display ("CS LOW");
        cs=0;
        assert(U100.state==csIdle);
        value=STARTVALUE;
        mode=CONTINUOUS;
#2      $display ("CS HIGH");
        cs=1;
        $display("Mode=%d",U100.mode);;
        $display("StartValue=%d",U100.startValue);
        $display("CurrentValue=%d",U100.currentValue);
        $display("state=%d",U100.state);
        assert(U100.currentValue==STARTVALUE); 
#2      assert(U100.currentValue==STARTVALUE-1);
#2      assert(U100.currentValue==STARTVALUE-2);
#2      assert(U100.state==csAlarm);
        assert(irq==1);
        assert(U100.currentValue==STARTVALUE);
#2      assert(U100.currentValue==STARTVALUE-1);
#2      assert(U100.currentValue==STARTVALUE-2);
#2      $display ("CS LOW");
        cs=0;
        value=1;
        mode=SINGLE_SHOT;
#2      $display ("CS HIGH");
        cs=1;
        $display("Mode=%d",U100.mode);;
        assert(U100.state==csIdle);
        assert(irq==0);
        assert(U100.currentValue==1);
#2      assert(U100.state==csCounting);
#2      assert(U100.currentValue==0);
        assert(irq==1);
        assert(U100.state==csAlarm);        
#2      assert(irq==0);
        assert(U100.currentValue==0);
        assert(U100.state==csIdle);        
#2      assert(U100.state==csIdle);        
#2      assert(U100.state==csIdle);        
        $display("Finished. time=%3d, clk=%b, reset=%b",$time, clk, reset);
        $finish(0);
end

endmodule