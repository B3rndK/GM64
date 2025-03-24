// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef GM64_H
`define GM64_H

`include "../reset/src/reset.v"


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

  typedef enum bit[7:0] {
    sstateReset=8'h00,
    sstateInitRAM=8'h01,
    sstateReadRAM=8'h02,
    sstateRun=8'h03,
    sstateRepeat=8'h04,
    sstateFinal=8'h05,
    sstateFailure=8'h10,
    sstateSuccess=8'h11,
    sstateXXX=8'h64
  } SStateMachine;

  SStateMachine state;
  SStateMachine next2;
 
  logic led;
  logic einaus;
  logic dataReadIn;
  int counter;
  logic rst;
  logic CE; // CE for memory controller    
  reg [23:0] addrBusMemCtrl; // out, address
  logic i_bank;
  logic dataReady;
  logic o_ready;
  logic [7:0] dataToWrite;
  logic [7:0] dataRead;
  logic [7:0] dataFromRam;
  logic busy;
  logic isReadOK;
  
  logic initDone;
  logic writeToRam;

  logic fpgaStart;  

  CC_USR_RSTN usr_rstn_inst (
   	.USR_RSTN(fpgaStart) // FPGA is configured and starts running
  );
  reset U20 (.clk(clk0), 
             .fpga_but1(fpga_but1), 
             .fpgaStart(fpgaStart), 
             .reset(rst)
            );  

  memCtrl U13_U25(
    .i_clkRAM(clk0), 
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
    .o_dataReady(dataReady)
    );

 assign o_led=(einaus==0);

 always_ff @(posedge clk0 or negedge rst) 
  if (!rst) begin
    state<=sstateXXX;
  end
  else state<=next2;  
  
  always_ff @(posedge clk0 or negedge rst) begin
    CE<=1;
    if (!rst) begin
      led<=0;
      next2<=sstateXXX;
      addrBusMemCtrl<=0;
      dataToWrite<=0;
      writeToRam<=0;
    end  
    else begin
      case (state)
        sstateXXX: next2<=sstateReset;
        sstateReset: begin                   
          if (!busy) begin
            next2<=sstateInitRAM;
          end
          else next2<=sstateReset;
        end
        
        sstateInitRAM: begin
          if (!busy) begin
            CE<=0;
            writeToRam<=1;
            addrBusMemCtrl<=16'hf000;
            dataToWrite<=8'h01;
            next2<=sstateReadRAM;
          end
        end

        sstateReadRAM: begin
          if (busy) next2<=sstateReadRAM;
          else begin
              CE<=0;
              writeToRam<=0;
              addrBusMemCtrl<=16'hf000;
              next2<=sstateRun;
          end
        end        
        
        sstateRun: begin
          if (!busy) begin
            next2<=sstateFinal;
          end
          else next2<=sstateRun;
        end
        
        sstateFinal: begin
          next2<=sstateFinal;
        end
      endcase
    end
  end

  always @(posedge dataReady, negedge rst) begin
    if (!rst) begin
      isReadOK=0;
      dataReadIn=0;
      einaus=0;
    end
    else if (dataReady==1) begin
      isReadOK=1;
      if (dataRead===8'h00) einaus=1;
      else einaus=0;
      dataReadIn=0;
    end
  end

endmodule  
`endif
