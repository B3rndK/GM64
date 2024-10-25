// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`timescale 1ns / 1ns

module memCtrl_tb();
  
  reg clkRAM;
  reg clkPhi0;
  reg reset;
  reg writeToRam;
  reg [15:0] addrBus;
  reg [7:0] dataToWrite;
  reg [7:0] dataRead;
  reg busy;
  reg [7:0] debug;
  reg io_psram_data0, io_psram_data1,io_psram_data2, io_psram_data3,io_psram_data4,
      io_psram_data5, io_psram_data6,io_psram_data7, io_psram_data8;
  reg [5:0] bank;
  reg  _dataReady;
  reg _cs;


wire dataReady;
assign dataReady=_dataReady;

memCtrl U13_U25(
  .clkPhi0(clkPhi0),
  .clkRAM(clkRAM), 
  .reset(reset), 
  .CS(_cs), 
  .write(writeToRam),
  .bank(bank),
  .addrBus(addrBus), 
  .o_psram_sclk(o_psram_sclk),  
  .dataToWrite(dataToWrite), 
  .dataRead(dataRead), 
  .io_psram_data0(io_psram_data0),
  .io_psram_data1(io_psram_data1),
  .io_psram_data2(io_psram_data2),
  .io_psram_data3(io_psram_data3),
  .io_psram_data4(io_psram_data4),
  .io_psram_data5(io_psram_data5),
  .io_psram_data6(io_psram_data6),
  .io_psram_data7(io_psram_data7),
  .o_psram_cs(o_psram_cs),
  .o_busy(busy),
  .o_dataReady(dataReady)
  );

initial begin
  _cs=0;
  clkRAM = 1'b1;
  clkPhi0 = 1'b0;
  _dataReady = 0;
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
          assert(U13_U25.o_busy==1);
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

#1        _cs=0;
          assert(U13_U25.state==stateIdle);
#10       assert(U13_U25.state==stateIdle);

          // Try writing 
#10       assert(U13_U25.state==stateIdle);
#1        writeToRam=1;
          bank=0;
          addrBus=49152;
          dataToWrite=8'b10101010;
          _cs=1;
#2        assert(busy==1);
          assert(o_psram_cs==0);
          assert(U13_U25.state==stateWrite_SendWriteCmd_1);
          assert(io_psram_data0==0);
          assert(io_psram_data1==='z); 
          assert(io_psram_data2==='z); 
          assert(io_psram_data3==='z); 
#2        assert(U13_U25.state==stateWrite_SendWriteCmd_2);
          assert(io_psram_data0==0);
#2        assert(U13_U25.state==stateWrite_SendWriteCmd_3);
          assert(io_psram_data0==1);
#2        assert(U13_U25.state==stateWrite_SendWriteCmd_4);
          assert(io_psram_data0==1);
#2        assert(U13_U25.state==stateWrite_SendWriteCmd_5);
          assert(io_psram_data0==1);
#2        assert(U13_U25.state==stateWrite_SendWriteCmd_6);
          assert(io_psram_data0==0);
#2        assert(U13_U25.state==stateWrite_SendWriteCmd_7);
          assert(io_psram_data0==0);
#2        assert(U13_U25.state==stateWrite_SendAddr19_16);
#2        assert(U13_U25.state==stateWrite_SendAddr15_12);
#2        assert(U13_U25.state==stateWrite_SendAddr11_8);
#2        assert(U13_U25.state==stateWrite_SendAddr7_4);
#2        assert(U13_U25.state==stateWrite_SendAddr3_0);
#2        assert(U13_U25.state==stateWrite_SendData7_4);
          assert(busy==1);
#2        assert(U13_U25.state==stateWrite_SendData3_0);
#2        assert(o_psram_cs==1);
          assert(U13_U25.state==stateIdle);
#20000    $display("Start read test. time=%3d, clk=%b, reset=%b",$time, clkRAM, reset);
          assert(U13_U25.state==stateIdle);
          assert(busy==0);
#2
          writeToRam=0;
          bank=0;
          addrBus=49152;
          _cs=1;
      
#2        assert(o_psram_cs==0);
          assert(busy==1);
          assert(U13_U25.state==stateRead_SendReadCmd_1);
#2        assert(U13_U25.state==stateRead_SendReadCmd_2);
#2        assert(U13_U25.state==stateRead_SendReadCmd_3);
#2        assert(U13_U25.state==stateRead_SendReadCmd_4);
#2        assert(U13_U25.state==stateRead_SendReadCmd_5);
#2        assert(U13_U25.state==stateRead_SendReadCmd_6);
#2        assert(U13_U25.state==stateRead_SendReadCmd_7);

#2        assert(U13_U25.state==stateRead_SendAddr19_16);
#2        assert(U13_U25.state==stateRead_SendAddr15_12);
#2        assert(U13_U25.state==stateRead_SendAddr11_8);
#2        assert(U13_U25.state==stateRead_SendAddr7_4);
#2        assert(U13_U25.state==stateRead_SendAddr3_0);

#2        assert(U13_U25.state==stateRead_WaitCycle_1);
#2        assert(U13_U25.state==stateRead_WaitCycle_2);
#2        assert(U13_U25.state==stateRead_WaitCycle_3);
#2        assert(U13_U25.state==stateRead_WaitCycle_4);
#2        assert(U13_U25.state==stateRead_WaitCycle_5);
#2        assert(U13_U25.state==stateRead_WaitCycle_6);
#2        assert(U13_U25.state==stateRead_WaitCycle_7);

#2        assert(U13_U25.state==stateRead3_0);
#2        assert(U13_U25.state==stateIdle);
          assert(busy==0);
          assert(o_psram_cs==1);          
#30000  $display("Finished. time=%3d, clk=%b, reset=%b",$time, clkRAM, reset);
        $finish(0);
end

endmodule