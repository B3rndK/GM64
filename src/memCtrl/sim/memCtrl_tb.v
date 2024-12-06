// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`timescale 10us / 1us

module memCtrl_tb();
  
  reg clkRAM;
  reg reset;
  reg _writeToRam;
  reg [23:0] address;
  reg [7:0] dataToWrite;
  reg [7:0] dataRead;
  reg busy;
  reg [7:0] debug;
  wire io_psram_data0, io_psram_data1,io_psram_data2, io_psram_data3,io_psram_data4,
      io_psram_data5, io_psram_data6,io_psram_data7, io_psram_data8;
  wire o_busy;
  reg  _dataReady;
  reg _cs;


wire dataReady;
assign dataReady=_dataReady;

memCtrl U13_U25(
  .i_clkRAM(clkRAM), 
  .reset(reset), 
  .i_cs(_cs), 
  .i_write(_writeToRam),
  .i_address(address), 
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
  .oBusy(o_busy),
  .o_dataReady(dataReady)
  );

initial begin
#1 _cs=1;
  reset=1;
  clkRAM = 1'b0;
  _dataReady = 0;
  forever begin
    #1 clkRAM <= ~clkRAM;  
  end
end


initial begin
          // $sdf_annotate("memCtrl_tb.sdf", U1);
          // $dumpoff; $dumpon;
          $dumpfile("sim/memCtrl_tb.vcd");
          $dumpvars(0, memCtrl_tb);
#2        $display("tb: Now resetting controller.");          
          reset=0; 
#2        assert(U13_U25.oBusy==1); //valid only after clk change.
#2        reset=1;
          $display ("Reset removed.");
#2        assert(U13_U25.delayCounter==U13_U25.initDelayInClkCyles);
#2        assert(U13_U25.delayCounter==U13_U25.initDelayInClkCyles-1);
#29998    assert(U13_U25.delayCounter==0);
#2        assert(U13_U25.state==sendQPIEnable);
          assert(U13_U25.psram_cs==0); 
          assert(io_psram_data0==U13_U25.qpiCommand[7]); // SI U7
          assert(io_psram_data4==U13_U25.qpiCommand[7]); // SI U9
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[6]); // SI U7
          assert(io_psram_data4==U13_U25.qpiCommand[6]); // SI U9
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[5]); // SI U7
          assert(io_psram_data4==U13_U25.qpiCommand[5]); // SI U9
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[4]); // SI U7
          assert(io_psram_data4==U13_U25.qpiCommand[4]); // SI U9
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[3]); // SI U7
          assert(io_psram_data4==U13_U25.qpiCommand[3]); // SI U9
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[2]); // SI U7
          assert(io_psram_data4==U13_U25.qpiCommand[2]); // SI U9
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[1]); // SI U7
          assert(io_psram_data4==U13_U25.qpiCommand[1]); // SI U9
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[0]); // SI U7
          assert(io_psram_data4==U13_U25.qpiCommand[0]); // SI U9
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(U13_U25.state==stateIdle);
          assert(o_busy==0);
          // Try writing 
#2        _cs=0; 
          _writeToRam=1;
          address=16'hAAAA;
          dataToWrite=8'b10101010;
#2        _cs=1; 
          assert(o_busy==1);
#2        assert(o_psram_cs==0);
          assert(U13_U25.state==sendQPIWriteCmd);
          assert(io_psram_data0==U13_U25.qpiCommand[7]);
          assert(io_psram_data1==='z); 
          assert(io_psram_data2==='z); 
          assert(io_psram_data3==='z); 
#2        assert(o_busy==1);
          assert(io_psram_data0==U13_U25.qpiCommand[6]);
          assert(io_psram_data1==='z); 
          assert(io_psram_data2==='z); 
          assert(io_psram_data3==='z); 
#2        assert(U13_U25.state==sendQPIWriteCmd);
          assert(io_psram_data0==U13_U25.qpiCommand[5]);
          assert(io_psram_data1==='z); 
          assert(io_psram_data2==='z); 
          assert(io_psram_data3==='z); 
#2        assert(U13_U25.state==sendQPIWriteCmd);
          assert(io_psram_data0==U13_U25.qpiCommand[4]);
          assert(io_psram_data1==='z); 
          assert(io_psram_data2==='z); 
          assert(io_psram_data3==='z); 
#2        assert(U13_U25.state==sendQPIWriteCmd);
          assert(io_psram_data0==U13_U25.qpiCommand[3]);
          assert(io_psram_data1==='z); 
          assert(io_psram_data2==='z); 
          assert(io_psram_data3==='z); 
#2        assert(U13_U25.state==sendQPIWriteCmd);
          assert(io_psram_data0==U13_U25.qpiCommand[2]);
          assert(io_psram_data1==='z); 
          assert(io_psram_data2==='z); 
          assert(io_psram_data3==='z); 
#2        assert(U13_U25.state==sendQPIWriteCmd);
          assert(io_psram_data0==U13_U25.qpiCommand[1]);
          assert(io_psram_data1==='z); 
          assert(io_psram_data2==='z); 
          assert(io_psram_data3==='z); 
#2        assert(U13_U25.state==sendQPIWriteCmd);
          assert(io_psram_data0==U13_U25.qpiCommand[0]);
          assert(io_psram_data1==='z); 
          assert(io_psram_data2==='z); 
          assert(io_psram_data3==='z); 
#2        assert(U13_U25.state==sendQPIAddress);
          assert(o_busy==1);
#500



/*
#2        assert(U13_U25.state==stateIdle);
#2        $display("Start read test. time=%3d, clk=%b, reset=%b",$time, clkRAM, reset);
          assert(U13_U25.state==stateIdle);
          assert(o_busy==0);
#2        _writeToRam=1;
          address=49152;
          _cs=1;
#2        assert(o_psram_cs==0);
          assert(o_busy==1);
          assert(U13_U25.state==sendQPIReadCommand);
#8        assert(U13_U25.state==readData);
#2        assert(U13_U25.state==waitCycle);
#2        assert(U13_U25.state==stateIdle);
          assert(busy==0);
          assert(o_psram_cs==1);   */       
#2        $display("Finished. time=%3d, clk=%b, reset=%b",$time, clkRAM, reset); 
  
          $finish(0);
end

endmodule