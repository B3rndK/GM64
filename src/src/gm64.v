// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef GM64_H
`define GM64_H

`include "../reset/src/reset.v"
`include "../memCtrl/src/memCtrl.vh"

module gm64(input clk0, // 10Mhz coming from FPGA
            input reset, 
            input fpga_but1, 
            output o_hsync, 
            output o_vsync, 
            output logic o_psram_cs,
            output logic o_psram_sclk,
            inout wire [7:0] io_psram_data,
            output [3:0] o_red, 
            output [3:0] o_green, 
            output [3:0] o_blue,
            output wire [0:0] o_led
            );

  /*
  typedef enum int {
  } SStateMachine;
*/
  enum logic [5:0]  {     
    sstateXXX,
    sstateReset,
    sstateInitRAM,
    sstateReadRAM,
    sstateWaitAfterWrite,
    sstateRun,
    sstateRepeat,
    sstateFinal,
    sstateFailure,
    sstateSuccess
 } state;
  
/*
  SStateMachine state;
  SStateMachine next2;
 */
  
  logic einaus;
  logic rst;
  reg i_cs; // CS for memory controller    
  reg [23:0] addrBusMemCtrl; // out, address
  logic i_bank;
  logic dataReady;

  logic [7:0] dataToWrite;
  logic [7:0] dataRead;
  logic busy;
  logic isReadOK;
  
  logic initDone;
  logic writeToRam;

  logic fpgaStart;  

  CC_USR_RSTN usr_rstn_inst (
   	.USR_RSTN(fpgaStart) // FPGA is configured and starts running
  );

logic clk100Mhz;
clockGen U31  (.clk10Mhz (clk0),
               .clk100Mhz (clk100Mhz)
              );

logic led,led2,led3;
assign o_led=!led && !led3;


reset U20 (.clk(clk0), 
             .fpga_but1(fpga_but1), 
             .fpgaStart(fpgaStart), 
             .reset(rst),
             .led(led2)
            );  

  memCtrl U13_U25(
    .i_clkRAM(clk0), 
    .reset(rst), 
    .i_cs(i_cs), 
    .i_write(writeToRam), 
    .i_address(addrBusMemCtrl), 
    .i_bank(i_bank),
    .o_psram_sclk(o_psram_sclk),
    .i_dataToWrite(dataToWrite), 
    .o_dataRead(dataRead), 
    .io_psram_data(io_psram_data),
    .o_psram_cs(o_psram_cs),
    .o_busy(busy),
    .o_dataReady(dataReady),
    .led(led)
    );
 
 int  counter;


  always_ff @(posedge clk0) begin
    if (!rst) begin
      state<=sstateReset;
      led3<=0;
      counter<=0;
      i_cs<=1;
      addrBusMemCtrl<=24'h1002;
      dataToWrite<=0;
      writeToRam<=0;
      i_bank<=0;
      counter<=24'd5550000;                
    end  
    else begin
      i_cs<=1;

      case (state) 
        sstateReset: begin                   
          counter<=counter-1;
          if (counter==0) state<=sstateInitRAM;
          else state<=sstateReset;
        end
        
        sstateInitRAM: begin
          if (!busy) begin
            i_cs<=0;
            i_bank<=0;
            writeToRam<=1;
            addrBusMemCtrl<=24'h01;
            dataToWrite<=8'hff;
            counter<=24'd555555;
            state<=sstateWaitAfterWrite;
          end
        end

        sstateWaitAfterWrite: begin
          counter<=counter-1;
          if (counter==0) state<=sstateReadRAM;
          else state<=sstateWaitAfterWrite;
        end

        sstateReadRAM: begin
          if (!busy) begin
            i_cs<=0;
            i_bank<=0;
            writeToRam<=0;
            addrBusMemCtrl<=24'h01; 
            state<=sstateRun;
          end
          else state<=sstateReadRAM;
        end
        
        sstateRun: begin
          if (dataReady==1 && !busy) begin
            state<=sstateFinal;
          end
          else begin
             state<=sstateRun;
          end
        end
        
        sstateFinal: begin
          if (dataRead>=8'h22) led3<=1;
          state<=sstateFinal;
        end

        default:
          state<=sstateXXX;
      endcase 
    end
  end

endmodule  
`endif
