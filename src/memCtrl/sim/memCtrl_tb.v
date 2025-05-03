// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`timescale 10us / 1us


// `include "../src/memCtrl.sv"
 `include "../src/memCtrl.vh"
module memCtrl_tb();
  
  logic clkRAM;
  logic reset;
  logic _writeToRam;
  logic [23:0] address;
  logic [7:0] dataToWrite;
  logic [7:0] dataRead;
  logic busy;
  reg [7:0] debug;
  wire io_psram_data0, io_psram_data1,io_psram_data2, io_psram_data3,io_psram_data4,
      io_psram_data5, io_psram_data6,io_psram_data7, io_psram_data8;
  logic o_busy;
  logic o_dataReady;
  wire o_psram_cs;
  reg _cs;
  logic bank;
  logic o_psram_sclk;
  StateMachine o_state;

memCtrl U13_U25(
  .i_clkRAM(clkRAM), 
  .reset(reset), 
  .i_cs(_cs), 
  .i_write(_writeToRam),
  .i_address(address), 
  .i_bank(bank),
  .o_psram_sclk(o_psram_sclk),  
  .i_dataToWrite(dataToWrite), 
  .o_dataRead(dataRead), 
  .io_psram_data0(io_psram_data0),
  .io_psram_data1(io_psram_data1),
  .io_psram_data2(io_psram_data2),
  .io_psram_data3(io_psram_data3),
  .io_psram_data4(io_psram_data4),
  .io_psram_data5(io_psram_data5),
  .io_psram_data6(io_psram_data6),
  .io_psram_data7(io_psram_data7),
  .o_psram_cs(o_psram_cs),
  .o_busy(o_busy),
  .o_dataReady(o_dataReady),
  .o_state(o_state)
  );

initial begin
#1 _cs=1;
  reset=1;
  clkRAM = 1'b0;
  forever begin
    #1 clkRAM = ~clkRAM;  
  end
end


initial begin
          // $sdf_annotate("memCtrl_tb.sdf", U1);
          // $dumpoff; $dumpon;
          $dumpfile("sim/memCtrl_tb.vcd");
          $dumpvars(0, memCtrl_tb);
#2        $display("Starting PSRAM write test bank 0. Resetting controller.");          
          reset=0;
          _cs=1; 
          bank=0;
#2        reset=1;
#100      ;
#1        assert(0==o_psram_sclk);   
#1        assert(0==o_psram_sclk);
#1        assert(0==o_psram_sclk);
#20       assert(o_busy==1); //valid only after clk change.
#1        assert(0==o_psram_sclk);   
#1        assert(0==o_psram_sclk);
#20       reset=1;
          $display ("Reset removed.");
#1        assert(0==o_psram_sclk);
#1        assert(0==o_psram_sclk); // clock should be stopped during reset
          assert(U13_U25.delayCounter==U13_U25.initDelayInClkCyles);
#2        assert(U13_U25.delayCounter==U13_U25.initDelayInClkCyles-1);
#29998    assert(U13_U25.delayCounter==0);
          assert(U13_U25.isInitialized==0);
#2        assert(1==o_psram_sclk);
          assert(U13_U25.o_state==sendQPIEnable);
          assert(U13_U25.psram_cs==0);          
          assert(io_psram_data0==U13_U25.qpiCommand[7]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#1        assert(0==o_psram_sclk);          
#1        assert(io_psram_data0==U13_U25.qpiCommand[6]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[5]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[4]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[3]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[2]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[1]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(io_psram_data0==U13_U25.qpiCommand[0]); // SI U7
          assert(io_psram_data1==='z); // SO U7
          assert(io_psram_data2==='z); // SO U7
          assert(io_psram_data3==='z); // SO U7
#2        assert(U13_U25.isInitialized==1);
          assert(U13_U25.o_state==stateIdle);
          assert(o_busy==0);
          // Try writing 
#2        _cs=0; 
          assert(U13_U25.shifter==0);
          _writeToRam=1;
          address=24'hAAAA;
          dataToWrite=8'b11110000;
#2        _cs=1; 
          assert(U13_U25.shifter==0);
          assert(o_busy==1);
#2        assert(U13_U25.o_state==sendQPIWriteCmd);
          assert(U13_U25.qpiCommand[7:0]==8'h38); // SPIQuadWrite
          assert(o_psram_cs==0);
          assert(io_psram_data0==1); // 0x03 // SIO 0 
          assert(io_psram_data1==1);   
          assert(io_psram_data2==0);   
          assert(io_psram_data3==0);   
#2        assert(io_psram_data0==0); // 0x08        
          assert(io_psram_data1==0);             
          assert(io_psram_data2==0);             
          assert(io_psram_data3==1);             
          assert(o_busy==1);
          assert(o_psram_cs==0);
#2        assert(U13_U25.o_state==sendQPIAddress);
          assert(U13_U25.shifter==3);
          assert(o_busy==1);
          assert(o_psram_cs==0);
          assert(io_psram_data0==0);
          assert(io_psram_data1==0);
          assert(io_psram_data2==0);
          assert(io_psram_data3==0);
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==0);
          assert(io_psram_data2==0);
          assert(io_psram_data3==0);
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==1);
          assert(io_psram_data2==0);
          assert(io_psram_data3==1);
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==1);
          assert(io_psram_data2==0);
          assert(io_psram_data3==1);
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==1);
          assert(io_psram_data2==0);
          assert(io_psram_data3==1);
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==1);
          assert(io_psram_data2==0);
          assert(io_psram_data3==1);
          // Write data
#2        assert(io_psram_data0==1);
          assert(io_psram_data1==1);
          assert(io_psram_data2==1);
          assert(io_psram_data3==1);          
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==0);
          assert(io_psram_data2==0);
          assert(io_psram_data3==0);

          assert(io_psram_data4===1'bZ);          
          assert(io_psram_data5===1'bZ);          
          assert(io_psram_data6===1'bZ);          
          assert(io_psram_data7===1'bZ);
#2        assert(U13_U25.psram_cs==1);
          assert(o_busy==0);
          assert(U13_U25.o_state==stateIdle);
#20       assert(U13_U25.o_state==stateIdle);          
#2        $display("Starting PSRAM read test bank 0. time=%3d, clk=%b, reset=%b",$time, clkRAM, reset);
          _cs=0; 
          _writeToRam=0;
          address=24'hAAAA;
#2        _cs=1; 
#2        assert(U13_U25.o_state==sendQPIReadCmd); 
          assert(io_psram_data3==U13_U25.qpiCommand[7]);
          assert(io_psram_data2==U13_U25.qpiCommand[6]);
          assert(io_psram_data1==U13_U25.qpiCommand[5]);
          assert(io_psram_data0==U13_U25.qpiCommand[4]);
          assert(o_dataReady==0);          
#2        assert(o_busy==1);
          assert(io_psram_data3==U13_U25.qpiCommand[3]);
          assert(io_psram_data2==U13_U25.qpiCommand[2]);
          assert(io_psram_data1==U13_U25.qpiCommand[1]);
          assert(io_psram_data0==U13_U25.qpiCommand[0]);
          assert(U13_U25.shifter==2);
#2        assert(U13_U25.o_state==sendQPIAddress);
          assert(o_busy==1);
          assert(o_psram_cs==0);
          assert(io_psram_data0==0);
          assert(io_psram_data1==0);
          assert(io_psram_data2==0);
          assert(io_psram_data3==0);
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==0);
          assert(io_psram_data2==0);
          assert(io_psram_data3==0);
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==1);
          assert(io_psram_data2==0);
          assert(io_psram_data3==1);
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==1);
          assert(io_psram_data2==0);
          assert(io_psram_data3==1);
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==1);
          assert(io_psram_data2==0);
          assert(io_psram_data3==1);
          assert(o_dataReady==0);
#2        assert(io_psram_data0==0);
          assert(io_psram_data1==1);
          assert(io_psram_data2==0);
          assert(io_psram_data3==1); // 24 Bit Address
          assert(U13_U25.shifter==8);
#2        assert(io_psram_data0===1'bZ);   // Start wait cycles...
          assert(io_psram_data1===1'bZ);          
          assert(io_psram_data2===1'bZ);          
          assert(io_psram_data3===1'bZ);
          assert(U13_U25.psram_cs==0);
#2        assert(io_psram_data0===1'bZ);   
          assert(io_psram_data1===1'bZ);          
          assert(io_psram_data2===1'bZ);          
          assert(io_psram_data3===1'bZ);
          assert(U13_U25.psram_cs==0);
#2        assert(io_psram_data0===1'bZ);   
          assert(io_psram_data1===1'bZ);          
          assert(io_psram_data2===1'bZ);          
          assert(io_psram_data3===1'bZ);
          assert(U13_U25.psram_cs==0);
#2        assert(io_psram_data0===1'bZ);   
          assert(io_psram_data1===1'bZ);          
          assert(io_psram_data2===1'bZ);          
          assert(io_psram_data3===1'bZ);
          assert(U13_U25.psram_cs==0);
#2        assert(io_psram_data0===1'bZ);   
          assert(io_psram_data1===1'bZ);          
          assert(io_psram_data2===1'bZ);          
          assert(io_psram_data3===1'bZ);
          assert(U13_U25.psram_cs==0);
#2        assert(io_psram_data0===1'bZ);   // 6th Waiting cycle
          assert(io_psram_data1===1'bZ);          
          assert(io_psram_data2===1'bZ);          
          assert(io_psram_data3===1'bZ);
          assert(U13_U25.psram_cs==0);
#2        assert(o_busy==1);    // 2x read cycles
          assert(U13_U25.psram_cs==0);
#2        assert(o_busy==1);    // 2x read cycles
          assert(U13_U25.psram_cs==0);
#2        assert(U13_U25.psram_cs==1);
#2        assert(o_dataReady==1);          
          assert(U13_U25.o_state==stateIdle);
          assert(o_busy==0);
#2        $display("Finished. time=%3d, clk=%b, reset=%b",$time, clkRAM, reset); 
          $finish(0);
end

endmodule
