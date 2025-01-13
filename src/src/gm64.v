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
`include "../counter/src/counter.v"
`include "../memCtrl/src/memCtrl.v"
`include "../sketchpad/src/sketchpad.v"

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
            output wire o_psram_cs,
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

  
  wire clkPhi0, clkPhi2;
  wire clkSys;
 
  reg [15:0] addrBus; // out, address
  reg [23:0] addrBusMemCtrl; // out, address
  wire [7:0] dataIn;  // write to memory
  wire [7:0] dataOut; // read from memory
  wire WE; // out, WriteEnable
  wire irq=0;
  wire rdy;
  wire nmi=0;
  wire  writeToRam=0;
  reg doWrite=0;
  reg [7:0] dataToWrite;
  reg [7:0] dataRead;
  reg [31:0] looper;
  wire [3:0] deb;
  
  assign writeToRam=doWrite;

  reg [7:0] debug_mem_state;
  wire busy;
  reg dataAck;
  wire memCtrlCE; // CE for memory controller    
  reg stop;
  reg fpgaStart;  
  reg clkDot, clkVideo;
  reg clkRAM;
  reg CE;

  logic rst;
  Color color;
  
  
  assign memCtrlCE=CE;
  logic dataReady;
 
  CC_USR_RSTN usr_rstn_inst (
   	.USR_RSTN(fpgaStart) // FPGA is configured and starts running
  );

  reset U20 (.clk(clk0), 
             .fpga_but1(fpga_but1), 
             .fpgaStart(fpgaStart), 
             .reset(rst)
            );  

  clockGen U31  (.clk10Mhz (clk0),
                 .clkSys (clkSys)
                );
  
  memCtrl U13_U25(
    .i_clkRAM(clkSys), 
    .reset(rst), 
    .i_cs(memCtrlCE), 
    .i_write(writeToRam), 
    .i_address(addrBusMemCtrl), 
    .o_psram_sclk(o_psram_sclk),
    .dataToWrite(dataToWrite), 
    .dataRead(dataRead), 
    .io_psram_data0(io_psram_data0),
    .io_psram_data1(io_psram_data1),
    .io_psram_data2(io_psram_data2),
    .io_psram_data3(io_psram_data3),
    .io_psram_data4(io_psram_data4),
    .io_psram_data5(io_psram_data5),
    .io_psram_data4(io_psram_data6),
    .io_psram_data5(io_psram_data7),
    .o_psram_cs(o_psram_cs),
    .o_busy(busy),
    .o_dataReady(dataReady)
    );
  
   
  VIC6569 U19 (
    .clkSys(clkSys),
    .reset(rst),
    .clkPhi0(clkPhi0),
    .clkPhi2(clkPhi2),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_red(o_red),
    .o_green(o_green),
    .o_blue(o_blue),
    .debugVIC(debugVIC) // testing only
  );

  cpu U7(.clk(clkPhi0), .reset(!rst), .AB(addrBus), .DI(dataIn), .DO(dataOut), .WE(WE), .IRQ(irq), .NMI(nmi), .RDY(rdy));
 
  reg [3:0] debugVIC;
  reg [3:0] nextCol;
  reg [24:0] coun;
  reg [63:0] cntCycle;
  reg [63:0] cntCycleOld;
/*
  // Testing
  sketchpad SKETCH (
     .clk(clk0), 
     .fpga_but1(fpga_but1),
     .signal(buttonPressed)
  );*/

  logic cycle=0;
  
  logic dataReady;
  logic success;

  typedef enum bit[7:0] {
    sstateReset=0,
    sstateInitRAM=1,
    sstateReadRAM=2,
    sstateRun=3,
    sstateFailure=90,
    sstateSuccess=98,
    sstateXXX=99
  } SStateMachine;

  SStateMachine state, next;

  always_ff @(posedge clkSys or negedge rst) 
    if (!rst) state<=sstateXXX;
    else state<=next;  

  // next logic
  always_comb begin
    next=sstateXXX;
    case (state)
      sstateXXX: next=sstateReset;
      sstateReset: if (cntCycleFast>64'd5000) next=sstateInitRAM;
                   else next=sstateReset;
      sstateInitRAM: if (bytesWritten==0) next=sstateInitRAM;
                    else next=sstateReadRAM;
      sstateReadRAM: if (bytesRead==0) next=sstateReadRAM;
                    else if (byteRead==8'haa) next=sstateSuccess;
                    else next=sstateFailure;
      sstateSuccess: next=sstateSuccess;                   
      sstateFailure: next=sstateFailure;
    endcase
  end
  
  logic [7:0] bytesWritten;
  logic [7:0] readRequested;
  logic [7:0] bytesRead;
  logic [7:0] byteRead;
  reg [63:0] cntCycleMS;
  
  reg [63:0] cntCycleOld;

  logic [63:0] cntCycleMS;
  logic [63:0] cntCycleFast;
  
  always @(posedge clkSys) begin
    cntCycleMS=cntCycle;
    cntCycleFast=cntCycleMS;
  end

  always_ff @(posedge clkSys or negedge rst) 
    if (!rst) begin
      debugVIC<=red;
      bytesWritten<=0;
      bytesRead<=0;
      readRequested<=0;
      CE<=1;
    end
    else begin   
      CE<=1;
      cntCycleOld<=cntCycleFast;
      case (next) 
        sstateInitRAM: begin
            debugVIC<=yellow;
            if (!busy && bytesWritten==0) begin
              CE<=0;
              doWrite<=1;
              addrBusMemCtrl<=24'h00fffc;
              dataToWrite<=8'haa;
              bytesWritten<=1;
            end
        end
        sstateReadRAM: begin
            if (!busy && bytesRead==0 && readRequested==0) begin
              readRequested<=1;
              CE<=0;
              doWrite<=0;
              addrBusMemCtrl<=24'h00fffc;
            end
            else if (dataReady && readRequested && bytesRead==0) begin
              bytesRead<=1;
              byteRead<=dataRead;
            end
        end
        sstateSuccess: begin
          debugVIC<=green;
        end

        sstateReset: begin
          debugVIC<=navy;
          /*
          if debugVIC<=navy;
          else debugVIC<=gray;*/
        end

        sstateFailure: begin
          debugVIC<=red;
        end
        
        default: debugVIC<=gray;
      endcase
      /*
      if (cntCycleOld!=cntCycle) begin
        if (doRead) begin    
          if (addrToRead==16'hfffc) begin
            debugVIC<=yellow;
            dataIn=8'h00;
          end
          else if (addrToRead==16'hfffd) begin
            debugVIC<=blue;
            dataIn=8'h03;
          end
          else if (addrToRead==16'h0300) begin
            debugVIC<=yellow;
            dataIn=8'h8d; // STA $d020
          end
          else if (addrToRead==16'h0301) begin
            debugVIC<=yellow;
            dataIn=8'h20; // STA $d020
          end
          else if (addrToRead==16'h0302) begin
            debugVIC<=yellow;
            dataIn=8'hd0; // STA $d020
          end
        end
        else begin
          if (success) debugVIC<=green;
        end
      end*/
    end
  logic _rdy;
  assign rdy=_rdy;
  
  logic doRead;
  logic [0:15] addrToRead;
  logic isRamInitialized;

 
  always_ff @(posedge clkPhi0 or negedge rst) 
    if (!rst) begin
      cntCycle<=0;
      success<=0;
      doRead<=0;
      _rdy<=0;
      isRamInitialized<=0;
    end
    else begin cntCycle<=cntCycle+1;
    doRead<=!WE;
    if (!WE) begin // read
      if (addrBus==16'hfffc) addrToRead<=addrBus;
    end
    else if (WE==1) begin // write
      case (addrBus)
        16'hd020: success<=1;
      endcase
    end
    end
endmodule  
`endif