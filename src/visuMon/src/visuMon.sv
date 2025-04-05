// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

`ifndef VISUMON
`define VISUMON

//`include "../syncGen/src/syncGen.v"
`include "visuMon.svh"

/* verilator lint_off TIMESCALEMOD */

/* Tool to simulate 64 LEDs using a simple VGA monitor display. 
   When we have VGA, why use LEDs? ;-)  */

module visuMon( input   logic i_clkVideo,
                input   logic i_reset,
                input   logic i_cs,    
                input   debugInfo_t i_debugInfo,
                output  o_hsync, 
                output  o_vsync, 
                output  [3:0] o_red, 
                output  [3:0] o_green, 
                output  [3:0] o_blue,
                inout   o_led);

debugInfo_t arrDebugInfo[63];

logic [3:0] _red, _green, _blue;
logic _display_on;

logic [9:0] o_hpos;
logic [9:0] o_vpos;

assign  o_red = _display_on ? _red : 4'b0000;
assign  o_green = _display_on ? _green : 4'b0000;
assign  o_blue = _display_on ? _blue  : 4'b0000;

/* verilator lint_off UNDRIVEN */
logic led;
assign o_led=!led;

//logic clkHDMI;
//logic [1:0] cntHDMI;
// assign clkHDMI=(cntHDMI==0 || cntHDMI==2);// We also need a video clock ~24.8Mhz for a quirk 50Hz HDMI graphics mode
/*
always @(posedge i_clk25Mhz)
begin
  if (!i_reset) cntHDMI<=0;
  else cntHDMI<=cntHDMI+1;
end
*/

parameter SCREENOFFSET_X=10;
parameter SCREENOFFSET_Y=10;
parameter LEDSIZE_X=8'd64;
parameter LEDSIZE_Y=8'd50;
parameter X_OFFSET=10;
parameter Y_OFFSET=10;
parameter MAX_LEDS_X=8;
parameter MAX_LEDS_Y=8;
parameter TOTAL_LEDSIZE_X=LEDSIZE_X+X_OFFSET;
parameter TOTAL_LEDSIZE_Y=LEDSIZE_Y+Y_OFFSET;  

logic reset;

syncGen sync_gen(
    .clk(i_clkVideo),
    .reset(reset),
    .o_hsync(o_hsync),
    .o_vsync(o_vsync),
    .o_display_on(_display_on),
    .o_hpos(o_hpos),
    .o_vpos(o_vpos)
);


always @(negedge i_cs) begin
    arrDebugInfo[i_debugInfo.ledNo]<=i_debugInfo;
end


logic [5:0] iLed;
logic [9:0] curX;
logic [9:0] curY;
//logic _status;

/* verilator lint_off UNUSEDSIGNAL */
debugInfo_t debug;

always_comb begin
  logic [10:0] ledInX;
  logic [10:0] ledInY;

  iLed='x;
  curX=o_hpos;
  curY=o_vpos;
  ledInX='x;
  ledInY='x;
  _red=4'b1000;
  _green=0;       
  _blue=0;
  //_status=0;
  debug=arrDebugInfo[1];


  /*
  noOnX=99;
  noOnY=99;
  iLed=99;
  if (curX>SCREENOFFSET_X) begin
    curX=o_hpos-SCREENOFFSET_X;
    noOnX=(curX/TOTAL_LEDSIZE_X);
  end
  if (curY>=SCREENOFFSET_Y) begin
    curY=o_hpos-SCREENOFFSET_Y;
    noOnY=(curY/TOTAL_LEDSIZE_Y);
  end
  if (noOnX<99 && noOnY<99) iLed=noOnX*noOnY;*/
  _red=8;           
  _green=2;       
  _blue=2;

  if (curX>SCREENOFFSET_X) begin
   if (curY>=SCREENOFFSET_Y) begin
      ledInX=((curX-SCREENOFFSET_X)/TOTAL_LEDSIZE_X);
      if (ledInX<=MAX_LEDS_X) begin
        ledInY=((curY-SCREENOFFSET_Y)/TOTAL_LEDSIZE_Y);
        if (ledInY<=MAX_LEDS_Y) begin
          ledInY=ledInY*MAX_LEDS_X;
          /* verilator lint_off WIDTHTRUNC */
          iLed=(ledInX+ledInY+1);
          debug=arrDebugInfo[iLed];
          if (debug.status) begin
            _red=debug[12:9];           
            _green=debug[8:5];       
            _blue=debug[4:1];

        end
      end
    end
  end
end
end

  /*  Berni's template...

  always_ff @(posedge i_clkRAM or negedge reset) 
    if (!reset) state<=stateXXX;
    else state<=next;  
  
  always_comb begin
    next=stateXXX;
    case (state)
      stateXXX:               next=stateReset;
      stateReset:             next=delayAfterReset;
      endcase
  end
  
  always_ff @(posedge i_clkRAM or negedge reset) begin
    if (!reset) begin
    end
    else begin

      case (next) 
        stateReset: begin
          ;
        end

        default: ;

      endcase
    end
  end */

endmodule
`endif 


  
  
 

  
  
