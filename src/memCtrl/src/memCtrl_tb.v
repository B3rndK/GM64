// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

`timescale 1us / 1ns

`include "assert.vh"
`include "memCtrl.vh"


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

#1 //errorOccured=0; 
  _cs=1;
  reset=1;
  clkRAM = 1'b0;
  forever begin
#1    clkRAM = ~clkRAM;  
  end
end


initial begin
          // $sdf_annotate("memCtrl_tb.sdf", U1);
          // $dumpoff; $dumpon;
          // $dumpfile("sim/memCtrl_tb.vcd");
          // $dumpvars(0, memCtrl_tb);
#2        $display("Starting PSRAM write test bank 0. Resetting controller.");          
         `ASSERT(1==U13_U25.o_psram_cs);
          reset=0;
          _cs=1; 
          bank=0;
#2        reset=1;
#2        `ASSERT(1==U13_U25.o_psram_cs);                
#100      ;
          // check that psram sclk is stopped.
#1        `ASSERT(0==o_psram_sclk);
#1        `ASSERT(0==o_psram_sclk);
#20       `ASSERT(o_busy==1); //valid only after clk change.
#1        `ASSERT(0==o_psram_sclk);   
#1        `ASSERT(0==o_psram_sclk);
#20       reset=1;
          $display ("Reset removed.");
#1        `ASSERT(0==o_psram_sclk);
          `ASSERT(U13_U25.delayCounter==U13_U25.initDelayInClkCyles);
          `ASSERT(U13_U25.isInitialized==0);
          // Waiting for >150us...
#15254    $display("U13_U25.delayCounter=%0d",U13_U25.delayCounter);
          `ASSERT(U13_U25.delayCounter==0);
#2        `ASSERT(1==o_psram_sclk);
          `ASSERT(U13_U25.o_state==sendQPIEnable);
          `ASSERT(U13_U25.psram_cs==0);          
          `ASSERT(io_psram_data0==U13_U25.qpiCommand[7]); // SI U7
          `ASSERT(io_psram_data1==='z); // SO U7
          `ASSERT(io_psram_data2==='z); // SO U7
          `ASSERT(io_psram_data3==='z); // SO U7
#1        `ASSERT(0==o_psram_sclk);          
#1        `ASSERT(io_psram_data0==U13_U25.qpiCommand[6]); // SI U7
          `ASSERT(io_psram_data1==='z); // SO U7
          `ASSERT(io_psram_data2==='z); // SO U7
          `ASSERT(io_psram_data3==='z); // SO U7
#2        `ASSERT(io_psram_data0==U13_U25.qpiCommand[5]); // SI U7
          `ASSERT(io_psram_data1==='z); // SO U7
          `ASSERT(io_psram_data2==='z); // SO U7
          `ASSERT(io_psram_data3==='z); // SO U7
#2        `ASSERT(io_psram_data0==U13_U25.qpiCommand[4]); // SI U7
          `ASSERT(io_psram_data1==='z); // SO U7
          `ASSERT(io_psram_data2==='z); // SO U7
          `ASSERT(io_psram_data3==='z); // SO U7
#2        `ASSERT(io_psram_data0==U13_U25.qpiCommand[3]); // SI U7
          `ASSERT(io_psram_data1==='z); // SO U7
          `ASSERT(io_psram_data2==='z); // SO U7
          `ASSERT(io_psram_data3==='z); // SO U7
#2        `ASSERT(io_psram_data0==U13_U25.qpiCommand[2]); // SI U7
          `ASSERT(io_psram_data1==='z); // SO U7
          `ASSERT(io_psram_data2==='z); // SO U7
          `ASSERT(io_psram_data3==='z); // SO U7
#2        `ASSERT(io_psram_data0==U13_U25.qpiCommand[1]); // SI U7
          `ASSERT(io_psram_data1==='z); // SO U7
          `ASSERT(io_psram_data2==='z); // SO U7
          `ASSERT(io_psram_data3==='z); // SO U7
#2        `ASSERT(io_psram_data0==U13_U25.qpiCommand[0]); // SI U7
          `ASSERT(io_psram_data1==='z); // SO U7
          `ASSERT(io_psram_data2==='z); // SO U7
          `ASSERT(io_psram_data3==='z); // SO U7
#2        `ASSERT(U13_U25.isInitialized==1);
          `ASSERT(U13_U25.o_state==stateIdle);
          `ASSERT(o_busy==0);
          // Try writing 
#2        _cs=0; 
          _writeToRam=1;
          address=24'hAAAA;
          dataToWrite=8'b11110000;
#2        `ASSERT(U13_U25.shifter==0);
           _cs=1; 
          `ASSERT(U13_U25.shifter==0);
          `ASSERT(o_busy==1);
#2        `ASSERT(U13_U25.o_state==sendQPIWriteCmd);
          `ASSERT(U13_U25.qpiCommand[7:0]==8'h38); // SPIQuadWrite
          `ASSERT(o_psram_cs==0);
          `ASSERT(io_psram_data0==1); // 0x03 // SIO 0 
          `ASSERT(io_psram_data1==1);   
          `ASSERT(io_psram_data2==0);   
          `ASSERT(io_psram_data3==0);   
#2        `ASSERT(io_psram_data0==0); // 0x08        
          `ASSERT(io_psram_data1==0);             
          `ASSERT(io_psram_data2==0);             
          `ASSERT(io_psram_data3==1);             
          `ASSERT(o_busy==1);
          `ASSERT(o_psram_cs==0);
#2        `ASSERT(U13_U25.o_state==sendQPIAddress);
          `ASSERT(U13_U25.shifter==3);
          `ASSERT(o_busy==1);
          `ASSERT(o_psram_cs==0);
          `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==0);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==0);
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==0);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==0);
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==1);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==1);
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==1);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==1);
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==1);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==1);
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==1);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==1);
          // Write data
#2        `ASSERT(io_psram_data0==1);
          `ASSERT(io_psram_data1==1);
          `ASSERT(io_psram_data2==1);
          `ASSERT(io_psram_data3==1);          
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==0);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==0);

          `ASSERT(io_psram_data4===1'bZ);          
          `ASSERT(io_psram_data5===1'bZ);          
          `ASSERT(io_psram_data6===1'bZ);          
          `ASSERT(io_psram_data7===1'bZ);
#2        `ASSERT(U13_U25.psram_cs==1);
          `ASSERT(o_busy==0);
          `ASSERT(U13_U25.o_state==stateIdle);
#20       `ASSERT(U13_U25.o_state==stateIdle);          
#2        $display("Starting PSRAM read test bank 0. time=%3d, clk=%b, reset=%b",$time, clkRAM, reset);
          _cs=0; 
          _writeToRam=0;
          address=24'hAAAA;
#2        _cs=1; 
#2        `ASSERT(U13_U25.o_state==sendQPIReadCmd); 
          `ASSERT(io_psram_data3==U13_U25.qpiCommand[7]);
          `ASSERT(io_psram_data2==U13_U25.qpiCommand[6]);
          `ASSERT(io_psram_data1==U13_U25.qpiCommand[5]);
          `ASSERT(io_psram_data0==U13_U25.qpiCommand[4]);
          `ASSERT(o_dataReady==0);          
#2        `ASSERT(o_busy==1);
          `ASSERT(io_psram_data3==U13_U25.qpiCommand[3]);
          `ASSERT(io_psram_data2==U13_U25.qpiCommand[2]);
          `ASSERT(io_psram_data1==U13_U25.qpiCommand[1]);
          `ASSERT(io_psram_data0==U13_U25.qpiCommand[0]);
          `ASSERT(U13_U25.shifter==2);
#2        `ASSERT(U13_U25.o_state==sendQPIAddress);
          `ASSERT(o_busy==1);
          `ASSERT(o_psram_cs==0);
          `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==0);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==0);
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==0);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==0);
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==1);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==1);
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==1);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==1);
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==1);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==1);
          `ASSERT(o_dataReady==0);
#2        `ASSERT(io_psram_data0==0);
          `ASSERT(io_psram_data1==1);
          `ASSERT(io_psram_data2==0);
          `ASSERT(io_psram_data3==1); // 24 Bit Address
          `ASSERT(U13_U25.shifter==8);
#2        `ASSERT(io_psram_data0===1'bZ);   // Start wait cycles...
          `ASSERT(io_psram_data1===1'bZ);          
          `ASSERT(io_psram_data2===1'bZ);          
          `ASSERT(io_psram_data3===1'bZ);
          `ASSERT(U13_U25.psram_cs==0);
#2        `ASSERT(io_psram_data0===1'bZ);   
          `ASSERT(io_psram_data1===1'bZ);          
          `ASSERT(io_psram_data2===1'bZ);          
          `ASSERT(io_psram_data3===1'bZ);
          `ASSERT(U13_U25.psram_cs==0);
#2        `ASSERT(io_psram_data0===1'bZ);   
          `ASSERT(io_psram_data1===1'bZ);          
          `ASSERT(io_psram_data2===1'bZ);          
          `ASSERT(io_psram_data3===1'bZ);
          `ASSERT(U13_U25.psram_cs==0);
#2        `ASSERT(io_psram_data0===1'bZ);   
          `ASSERT(io_psram_data1===1'bZ);          
          `ASSERT(io_psram_data2===1'bZ);          
          `ASSERT(io_psram_data3===1'bZ);
          `ASSERT(U13_U25.psram_cs==0);
#2        `ASSERT(io_psram_data0===1'bZ);   
          `ASSERT(io_psram_data1===1'bZ);          
          `ASSERT(io_psram_data2===1'bZ);          
          `ASSERT(io_psram_data3===1'bZ);
          `ASSERT(U13_U25.psram_cs==0);
#2        `ASSERT(io_psram_data0===1'bZ);   // 6th Waiting cycle
          `ASSERT(io_psram_data1===1'bZ);          
          `ASSERT(io_psram_data2===1'bZ);          
          `ASSERT(io_psram_data3===1'bZ);
          `ASSERT(U13_U25.psram_cs==0);
#2        `ASSERT(o_busy==1);    // 2x read cycles
          `ASSERT(U13_U25.psram_cs==0);
#2        `ASSERT(o_busy==1);    // 2x read cycles
          `ASSERT(U13_U25.psram_cs==0);
#2        `ASSERT(U13_U25.psram_cs==1);
#2        `ASSERT(o_dataReady==1);          
          `ASSERT(U13_U25.o_state==stateIdle);
          `ASSERT(o_busy==0);
#100      `ASSERT(o_busy==0);          
          `FINAL_REPORT;
#2        $display("Finished. time=%3d, clk=%b, reset=%b",$time, clkRAM, reset); 
          $finish(0);
end

endmodule
