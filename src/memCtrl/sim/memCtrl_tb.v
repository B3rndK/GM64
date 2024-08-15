
// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`timescale 1ns / 1ns

module memCtrl_tb();
  reg clkRAM;
  reg  reset;
  reg memCtrlCE;
  reg writeToRam;
  reg [15:0] addrBus;
  reg [7:0] dataToWrite;
  reg [7:0] dataRead;
  reg busy;
  reg io_psram_data0, io_psram_data1,io_psram_data2, io_psram_data3,io_psram_data4,
      io_psram_data5, io_psram_data6,io_psram_data7, io_psram_data8;
  reg [3:0] bank;

memCtrl U13_U25(
  .clk(clkRAM), 
  .reset(reset), 
  .CE(memCtrlCE), 
  .write(writeToRam),
  .bank(bank),
  .addrBus(addrBus), 
  .dataToWrite(dataToWrite), 
  .dataRead(dataRead), 
  .busy(busy),
  .io_psram_data0(io_psram_data0),
  .io_psram_data1(io_psram_data1),
  .io_psram_data2(io_psram_data2),
  .io_psram_data3(io_psram_data3),
  .io_psram_data4(io_psram_data4),
  .io_psram_data5(io_psram_data5),
  .io_psram_data6(io_psram_data6),
  .io_psram_data7(io_psram_data7),
  .o_psram_cs(o_psram_cs),
  .o_psram_sclk(o_psram_sclk)
  );
  
initial begin
  clkRAM = 1'b1;
  forever #1 clkRAM = ~clkRAM; 
end  

initial begin
          // $sdf_annotate("memCtrl_tb.sdf", U1);
          // $dumpoff; $dumpon;
          $dumpfile("sim/memCtrl_tb.vcd");
          $dumpvars(0, memCtrl_tb);
#1        $display("tb: Now resetting controller.");          
          reset=1;
#2          
          // $monitor(U13_U25.delayCounter);
          assert(U13_U25.delayCounter==U13_U25.initDelayInClkCyles);
#3
#10       reset=0;
          $display ("Reset removed.");
          assert(U13_U25.state==stateInit_1);
#15000    assert(U13_U25.state==stateInit_2);
#2
          assert(U13_U25.state==stateEnableQPI);
#2          
          assert(U13_U25.psram_cs==0); 
          assert(io_psram_data0==enableQPIMode[7]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data4==enableQPIMode[7]); // SI U9
          assert(io_psram_data5==='z); // SO U9
#2
          assert(io_psram_data0==enableQPIMode[6]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data4==enableQPIMode[6]); // SI U9
          assert(io_psram_data5==='z); // SO U9
#2
          assert(io_psram_data0==enableQPIMode[5]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data4==enableQPIMode[5]); // SI U9
          assert(io_psram_data5==='z); // SO U9
#2
          assert(io_psram_data0==enableQPIMode[4]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data4==enableQPIMode[4]); // SI U9
          assert(io_psram_data5==='z); // SO U9
#2
          assert(io_psram_data0==enableQPIMode[3]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data4==enableQPIMode[3]); // SI U9
          assert(io_psram_data5==='z); // SO U9
#2
          assert(io_psram_data0==enableQPIMode[2]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data4==enableQPIMode[2]); // SI U9
          assert(io_psram_data5==='z); // SO U9
#2
          assert(io_psram_data0==enableQPIMode[1]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data4==enableQPIMode[1]); // SI U9
          assert(io_psram_data5==='z); // SO U9
#2
          assert(io_psram_data0==enableQPIMode[0]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data4==enableQPIMode[0]); // SI U9
          assert(io_psram_data5==='z); // SO U9

#1        memCtrlCE=0;
          assert(U13_U25.state==stateIdle);
#10       assert(U13_U25.state==stateIdle);

          // Try writing 16 bits bits...



$display("Finished. time=%3d, clk=%b, reset=%b",$time, clkRAM, reset);
          $finish(0);
end

endmodule;