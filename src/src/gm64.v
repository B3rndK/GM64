// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef GM64_H
`define GM64_H

//`include "clockGclockGen.sv"
//`include "syncGen.v"
//`include "VIC6569.v"
//`include "reset.v"
//`include "MOS6502/src/alu.v"
//`include "MOS6502/src/cpu.v"
//`include "counter.v"
//`include "memCtrl.v"
//`include "sketchpad.v"
`include "../visuMon/src/visuMon.svh"
/*
typedef enum bit[3:0] {
  black=0,
  red=1,
  green=2,
  yellow=3,
  navy=4,
  blue=5,
  gray=6
} Color;
*/

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
            output o_led
            );

  debugInfo_t debugInfo;

  var led;
  var einaus;
  assign o_led=einaus;
  int counter;
  wire clkSys;

  clockGen U31  (.clk10Mhz (clk0),
                 .clkSys (clkSys)
                );

  logic csVisuMon;
  visuMon U99 ( .i_clkVideo(clkSys),
                .i_reset(1),
                .i_cs(csVisuMon),    
                .i_debugInfo(debugInfo),
                .o_hsync(o_hsync), 
                .o_vsync(o_vsync), 
                .o_red(o_red), 
                .o_green(o_green), 
                .o_blue(o_blue),
                .o_led(o_led));

  always @(posedge clk0, negedge fpga_but1)
  begin
    if (!fpga_but1) begin
      counter=1;
      debugInfo.ledNo=1;
      debugInfo.color=Green;
      debugInfo.status=1;
      csVisuMon=0;
    end
    else begin
       csVisuMon=1;
       counter++;
       if (counter>10) counter=1;
       einaus=counter % 5;
    end

  end

endmodule  
`endif
/*
  debugInfo_t debugInfo;

  wire clkPhi0, clkPhi2;
  logic clkSys;
 
  reg [15:0] addrBus; // out, address
  reg [23:0] addrBusMemCtrl; // out, address
  reg [23:0] addressToTest; // out, address
  logic [7:0] dataIn;  // write to memory
  logic [7:0] dataOut; // read from memory
  logic WE; // out, WriteEnable
  wire irq=0;
  wire rdy;
  wire nmi=0;
  logic  writeToRam;
  
  logic [7:0] dataToWrite;
  logic [7:0] dataRead;
  wire [3:0] deb;

  reg [7:0] debug_mem_state;
  logic busy;
  reg dataAck;
  logic CE; // CE for memory controller    
  reg stop;
  reg fpgaStart;  
  reg clkDot, clkVideo;
  reg clkRAM;

  logic rst;
  Color color;
  
  logic i_bank;
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
    .i_cs(CE), 
    .i_write(writeToRam), 
    .i_address(addrBusMemCtrl), 
    .i_bank(i_bank),
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
    .o_busy(busy),
    .o_dataReady(dataReady),
    .o_led(o_led)
    );

  logic csVisuMon;
  visuMon U99 ( .i_clkVideo(clkSys),
                .i_reset(rst),
                .i_cs(csVisuMon),    
                .i_debugInfo(debugInfo),
                .o_hsync(o_hsync), 
                .o_vsync(o_vsync), 
                .o_red(o_red), 
                .o_green(o_green), 
                .o_blue(o_blue),
                .o_led(o_led));

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

  // cpu U7(.clk(clkPhi0), .reset(!rst), .AB(addrBus), .DI(dataIn), .DO(dataOut), .WE(WE), .IRQ(irq), .NMI(nmi), .RDY(rdy));

  reg [3:0] debugVIC;
  reg [3:0] nextCol;
  //reg [24:0] counter;
  reg [63:0] cntCycle;
  reg [63:0] cntCycleOld;

  logic [7:0] bytesWritten;
  logic readRequested;
  logic [7:0] bytesRead;
  logic [7:0] byteRead;


  // Testing
  sketchpad SKETCH (
     .clk(clk0), 
     .fpga_but1(fpga_but1),
     .signal(buttonPressed)
  );

  logic cycle;
  
  logic led;
  //assign o_led=!led;

  logic success;
  logic [23:0] noAddressesToTest;
  
  typedef enum bit[7:0] {
    sstateReset=0,
    sstateInitRAM=1,
    sstateReadRAM=2,
    sstateRun=3,
    sstateRepeat=4,
    sstateFinal=5,
    sstateFailure=90,
    sstateSuccess=98,
    sstateXXX=99
  } SStateMachine;

  SStateMachine state;
  SStateMachine next2;

  always_ff @(posedge clkSys or negedge rst) 
    if (!rst) state<=sstateXXX;
    else state<=next2;  

  logic [31:0] cntDelay;

  // next logic
  always_comb begin
    case (state)
      sstateXXX: next2=sstateReset;
      sstateReset: begin                   
                    if (cntDelay>32'd50000) next2=sstateInitRAM;
                    else next2=sstateReset;
                   end
      sstateInitRAM: if (bytesWritten==0) begin
                      next2=sstateInitRAM;
                    end
                    else begin
                      next2=sstateReadRAM;
                    end
      sstateReadRAM: if (bytesRead==0) begin
                        next2=sstateReadRAM;
                     end
                     else if (bytesRead>0) begin
                       if (byteRead==8'haa) next2=sstateSuccess;
                       else next2=sstateFailure;
                     end
      sstateSuccess: if (!busy) next2=sstateRepeat;                   
                     else next2=sstateSuccess;                   
      sstateFailure: next2=sstateFailure;
      sstateRepeat:  if (addressToTest>noAddressesToTest) next2=sstateFinal;
                     else next2=sstateInitRAM;

      sstateFinal:    next2=sstateFinal;
      //default:        next2=sstateXXX;
    endcase
  end
  
  always_ff @(posedge clkSys or negedge rst) 
    if (!rst) begin
      csVisuMon<=1;
      debugInfo[18:0]<='b0;
      addrBusMemCtrl<=0;
      writeToRam<=0;
      dataToWrite<=0;
      
      cntDelay<=0;
      debugVIC<=4;
      bytesWritten<=0;
      bytesRead<=0;
      byteRead<=0;
      readRequested<=0;
      i_bank<=1;
      CE<=1;
      led<=0;
      noAddressesToTest=24'd4096000; // We want to write and read this number of addresses
      addressToTest<=24'h1;
    end
    else begin   
      case (next2) 
        sstateInitRAM: begin
          debugInfo.ledNo<=1;
          debugInfo.color<=Red;
          debugInfo.status<=1;
          csVisuMon<=0;

          if (!busy && bytesWritten==0) begin
            CE<=0;
            writeToRam<=1;
            addrBusMemCtrl<=addressToTest;
            dataToWrite<=8'haa;
            bytesWritten<=1;
          end
        end
        sstateReadRAM: begin
          debugInfo.ledNo<=2;
          debugInfo.color<=Green;
          debugInfo.status<=1;
          csVisuMon<=0;
          led<=0;
          if (CE==0) CE<=1;
          else if (dataReady && !busy) begin
              debugVIC<=2;
              bytesRead<=1;
              byteRead<=dataRead;
          end
          else begin
            if (!busy && !readRequested) begin
              readRequested<=1;
              CE<=0;
              writeToRam<=0;
              addrBusMemCtrl<=addressToTest;
            end
          end
        end

        sstateSuccess: begin
          debugInfo.ledNo<=3;
          debugInfo.color<=Blue;
          debugInfo.status<=1;
          csVisuMon<=0;
          CE<=1;
          debugVIC<=3;
          led<=1;
        end
        
        sstateRepeat: begin
          CE<=1;
          bytesWritten<=0;
          bytesRead<=0;
          byteRead<=0;
          readRequested<=0;
          if (addressToTest<=noAddressesToTest) addressToTest<=addressToTest+1;
        end

        sstateFinal: begin
          debugVIC<=3;
        end

        sstateReset: begin
          cntDelay<=cntDelay+1;
          debugVIC<=1;
        end

        sstateFailure: begin
          if (addressToTest>2) debugVIC<=2;
          else debugVIC<=1;
        end
        
        default: debugVIC<=4;
      endcase*/
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
      end
    end*/

/*
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
      addrToRead<=0;
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
    end*/

