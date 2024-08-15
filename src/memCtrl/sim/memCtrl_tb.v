
// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`timescale 1ns / 1ns

module memCtrl_tb();
  reg clkRAM;
  reg  reset;
  reg memCtrlCE;
  reg writeToRam;
  reg [15:0] addrBus;
  reg [3:0] numberOfBytesToWrite;
  reg [15*7:0] dataToWrite;
  reg [7:0] dataRead;
  reg busy;
  reg io_psram_data0, io_psram_data1,io_psram_data2, io_psram_data3,io_psram_data4,
      io_psram_data5, io_psram_data6,io_psram_data7, io_psram_data8;
  
  //reg o_psram_cs;
  //reg o_psram_sclk;

memCtrl U13_U25(.clk(clkRAM), .reset(reset), .CE(memCtrlCE), .write(writeToRam), .addrBus(addrBus), 
  .numberOfBytesToWrite(numberOfBytesToWrite), 
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
  clkRAM = 1'b0;
  forever #1 clkRAM = ~clkRAM; 
end  

initial begin
  // $sdf_annotate("memCtrl_tb.sdf", U1);
  // $dumpoff; $dumpon;
          $dumpfile("sim/memCtrl_tb.vcd");
          $dumpvars(0, memCtrl_tb);
#1        $display("No reset until FPGA reports restart: time=%3d, clk=%b, reset=%b",$time, clkRAM, reset);
#1000000  $display("Finished. time=%3d, clk=%b, reset=%b",$time, clkRAM, reset);
          $finish(0);
end

endmodule;