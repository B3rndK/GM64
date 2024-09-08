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

typedef enum bit[3:0] {
  black=0,
  red=1,
  green=2,
  yellow=3,
  navy=4,
  blue=5,
  gray=6
} Color;


module gm64(input clk0, // 10Mhz coming from FPGA
            input reset, 
            input fpga_but1, 
            output o_hsync, 
            output o_vsync, 
            output o_psram_cs,
            output wire o_psram_sclk,
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
            );

  
  reg clkPhi0;
  
  reg [15:0] addrBus; // out, address
  reg [5:0] bank;
  wire [7:0] dataIn;  // write to memory
  wire [7:0] dataOut; // read from memory
  wire WE; // out, WriteEnable
  wire irq=0;
  wire rdy=1;
  wire nmi=0;
  reg  writeToRam;
  reg [7:0] dataToWrite;
  reg [7:0] dataRead;
  wire [3:0] debugValue;
  reg [3:0] debug;
  reg [24:0] looper;
  wire [3:0] deb;
  
  reg [7:0] debug_mem_state;
  reg busy;
  reg o_dataReady;
  reg dataAck;
  reg memCtrlCE; // CE for memory controller    
  reg stop;
  reg fpgaStart;  
  reg clkDot, clkVideo;
  
  reg clkRAM;
  
  reg clk100Mhz;
  assign o_psram_sclk=clk100Mhz;

  CC_USR_RSTN usr_rstn_inst (
   	.USR_RSTN(fpgaStart) // FPGA is configured and starts running
  );
  
  always@(posedge clkRAM or negedge clkRAM)
  begin
      if (clkRAM) begin
        clk100Mhz=clkRAM;
      end 
      else begin
        clk100Mhz=clkRAM;
      end
  end;

  reset U20 (.clk(clk0), .fpga_but1(fpga_but1), .fpgaStart(fpgaStart), .reset(reset));  

  clockGen U31 (.clk10Mhz (clk0),
               .clkRAM (clkRAM),
               .clkDot (clkDot),
               .clkVideo (clkVideo),
               .reset (!reset) // low active
              );

  memCtrl U13_U25(.clk(clkRAM), .reset(reset), .CE(memCtrlCE), .write(writeToRam), .bank(bank), .addrBus(addrBus), 
    .dataToWrite(dataToWrite), 
    .dataRead(dataRead), 
    .isBusy(busy),
    .io_psram_data0(io_psram_data0),
    .io_psram_data1(io_psram_data1),
    .io_psram_data2(io_psram_data2),
    .io_psram_data3(io_psram_data3),
    .io_psram_data4(io_psram_data4),
    .io_psram_data5(io_psram_data5),
    .io_psram_data4(io_psram_data6),
    .io_psram_data5(io_psram_data7),
    .o_psram_cs(o_psram_cs),
    .o_dataReady(o_dataReady),
    .debug(debug_mem_state)
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
    .debugValue(debug) // testing only
  );
  
  cpu U7(.clk(clk0), .reset(!reset), .AB(addrBus), .DI(dataIn), .DO(dataOut), .WE(WE), .IRQ(irq), .NMI(nmi), .RDY(rdy));

  always@(posedge o_dataReady)
  begin
    if (o_dataReady) begin
      if (dataRead==20) begin
        dataAck=1;
        debug=red;
      end
      else if (dataRead!=20) begin
        //debug=gray;
      end
    end
  end

  always @(posedge clkPhi0  or negedge reset)
  begin
    if (!reset) begin
      looper=0;
      memCtrlCE=0;
      debug=black;
      stop=0;
    end
    else begin
      if (stop==1) begin
      end
      else if (stop==0) begin
        if (looper<=1300000) begin
          debug=green;
        end
        else if (looper>2000000 && looper<=3000000) begin
          debug=yellow;
        end
        else if (looper>3000000 && looper<=4000000) begin
          debug=blue;  
        end
        else if (looper>4000000 && looper<=5000000) begin
          if (looper==4000001) begin
            addrBus=49152;
            bank=0;
            dataToWrite=20;
            writeToRam=1;
            memCtrlCE=1;
          end
          if (looper==4000002) begin
            if (busy==0) begin
              addrBus=49152;
              bank=0;
              dataToWrite=0;
              writeToRam=0;
              memCtrlCE=1;
            end
          end
          if (looper==4000003) begin
            if (dataIn==20) begin
              debug=red;
              stop=1;
            end
          end
        end
        if (looper>5000000) begin
          looper=0;
        end
        looper++;
      end
    end
  end  
endmodule  

/*
      else if (looper==39002) begin
          if (dataRead==0) begin
            debug=6; // green
          end
          else begin
            debug=8; // red
          end
      end
      if (looper>39002) begin
        looper=39002;
        debug=6;
      end
      /* This is a little 6502 test which will execute a program at $c000 after reset 
         and "store" a value in $d020 

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
      */



`endif