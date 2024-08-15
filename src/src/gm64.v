// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef GM64_H
`define GM64_H

`include "../clockGen/src/clockGen.v"
`include "../syncGen/src/syncGen.v"
`include "../VIC6569/src/VIC6569.v"
`include "../reset/src/reset.v"
`include "../MOS6502/src/alu.v"
`include "../MOS6502/src/cpu.v"
`include "../memCtrl/src/memCtrl.v"

module gm64(input clk0, // 10Mhz coming from FPGA
            input reset, 
            input fpga_but1, 
            output o_hsync, 
            output o_vsync, 
            output o_psram_cs,
            output o_psram_sclk,
            inout  wire io_psram_data0,
            inout  wire io_psram_data1,
            inout  wire io_psram_data2,
            inout  wire io_psram_data3,
            inout  wire io_psram_data4,
            inout  wire io_psram_data5,
            inout  wire io_psram_data6,
            inout  wire io_psram_data7,            
            output [3:0] o_red, 
            output [3:0] o_green, 
            output [3:0] o_blue,
            // Test only
            output o_clkRAM,
            output o_clkDot,
            output o_clkVideo
            );

 
  wire clkVideo, clkRAM, clkDot, clkPhi0;

  //assign o_clkRAM=clkRAM;
  assign o_clkDot=clkDot;
  //assign o_clkVideo=clkVideo;
  
  reg [15:0] addrBus; // out, address
  reg [6:0] bank;
  wire [7:0] dataIn;  // write to memory
  wire [7:0] dataOut; // read from memory
  wire WE; // out, WriteEnable
  wire memCtrlCE; // CE for memory controller    
  wire irq=0;
  wire rdy=1;
  wire nmi=0;
  wire writeToRam;
  wire [3:0] numberOfBytesToWrite;
  wire [15*7:0] dataToWrite;
  wire [7:0] dataRead;
  wire [3:0] debugValue;
  reg [3:0] debug;
  assign debugValue=debug;

  CC_USR_RSTN usr_rstn_inst (
   	.USR_RSTN(fpgaStart) // FPGA is configured and starts running
  );
  
  reset U20 (.clk(clk0), .fpga_but1(fpga_but1), .fpgaStart(fpgaStart), .reset(reset));  

  clockGen U31 (.clk10Mhz (clk0),
               .clkRAM (clkRAM),
               .clkDot (clkDot),
               .clkVideo (clkVideo),
               .reset (!reset) // low active
              );

  memCtrl U13_U25(.clk(clkRAM), .reset(reset), .CE(memCtrlCE), .write(writeToRam), .bank(bank), .addrBus(addrBus), 
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
    .io_psram_data4(io_psram_data6),
    .io_psram_data5(io_psram_data7),
    .o_psram_cs(o_psram_cs),
    .o_psram_sclk(o_psram_sclk)
    );
  
  VIC6569 U19 (
    .clk(clkVideo),
    .clkDot(clkDot),
    .reset(!reset),
    .clkPhi0(clkPhi0),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_red(o_red),
    .o_green(o_green),
    .o_blue(o_blue),
    .debugValue(debugValue) // testing only
  );
  
  cpu U7(.clk(clk0), .reset(!reset), .AB(addrBus), .DI(dataIn), .DO(dataOut), .WE(WE), .IRQ(irq), .NMI(nmi), .RDY(rdy));

  
  always @(posedge clkRAM  or negedge reset)
  begin
    if (!reset) debug=1;
    else begin

      /* This is a little 6502 test which will execute a program at $c000 after reset 
         and "store" a value in $d020 */ 

      if (addrBus==16'hfffc) dataIn=8'h00;
      if (addrBus==16'hfffd) dataIn=8'hc0;
      if (addrBus==16'hc000) begin
        dataIn=8'h8d; // STA $d020
        debug=5;
      end
      if (addrBus==16'hc001) dataIn=8'h20; 
      if (addrBus==16'hc002) dataIn=8'hd0; 
      if (addrBus==16'hc003) dataIn=8'h4c; // JMP $c000
      if (addrBus==16'hc004) dataIn=8'h00; 
      if (addrBus==16'hc005) dataIn=8'hc0; 
      if (addrBus==16'hd020 && WE) debug=2; // sta $d020 executed, show colour as positive response
    end
  end

endmodule  

`endif