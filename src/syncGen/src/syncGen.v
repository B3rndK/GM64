// SPDX-License-Identifier: CC-BY-1.0

`ifndef SYNCGEN_H
`define SYNCGEN_H

/*
Video sync generator, used to drive a VGA monitor.
Timing from: https://en.wikipedia.org/wiki/Video_Graphics_Array
Based on Steven Hugg: https://github.com/sehugg/fpga-examples
*/

module syncGen(clk, reset, o_hsync, o_vsync, o_display_on, o_hpos, o_vpos);

  input clk;
  input reset;
  output reg o_hsync, o_vsync;
  output o_display_on;
  output reg [9:0] o_hpos;
  output reg [9:0] o_vpos;

  // horizontal constants PAL 720x576/50Hz for C64
  
  parameter H_DISPLAY       = 720; // horizontal display width
  parameter H_BACK          =  52; // horizontal left border (back porch)
  parameter H_FRONT         =  16; // horizontal right border (front porch)
  parameter H_SYNC          =  32; // horizontal sync width
  // vertical constants
  parameter V_DISPLAY       = 576; // vertical display height
  parameter V_TOP           =  13; // vertical top border
  parameter V_BOTTOM        =  10; // vertical bottom border
  parameter V_SYNC          = 2; // vertical sync # lines
  // derived constants
  parameter H_SYNC_START    = H_DISPLAY + H_FRONT;
  parameter H_SYNC_END      = H_DISPLAY + H_FRONT + H_SYNC - 1;
  parameter H_MAX           = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1;
  parameter V_SYNC_START    = V_DISPLAY + V_BOTTOM;
  parameter V_SYNC_END      = V_DISPLAY + V_BOTTOM + V_SYNC - 1;
  parameter V_MAX           = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1;

  
  wire hmaxxed = (o_hpos == H_MAX) || reset;	// set when hpos is maximum
  wire vmaxxed = (o_vpos == V_MAX) || reset;	// set when vpos is maximum
  
  // horizontal position counter
  always @(posedge clk)
  begin
    o_hsync <= (o_hpos>=H_SYNC_START && o_hpos<=H_SYNC_END);
    if(hmaxxed)
      o_hpos <= 0;
    else
      o_hpos <= o_hpos + 1;
  end

  // vertical position counter
  always @(posedge clk)
  begin
    o_vsync <= (o_vpos>=V_SYNC_START && o_vpos<=V_SYNC_END);
    if(hmaxxed)
      if (vmaxxed)
        o_vpos <= 0;
      else
        o_vpos <= o_vpos + 1;
  end
  
  // display_on is set when beam is in "safe" visible frame
  assign o_display_on = (o_hpos<H_DISPLAY) && (o_vpos<V_DISPLAY);

endmodule

`endif
