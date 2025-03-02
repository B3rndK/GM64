// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef COUNTER_H
`define COUNTER_H

typedef enum reg {
  SINGLE_SHOT=0,
  CONTINUOUS=1
} CounterMode;

typedef enum bit[1:0] {
  csIdle=0,
  csCounting=1,
  csAlarm=2
} CounterState;

localparam reg HIGH=1;
localparam reg LOW=0;

/* Counter starting from i_value downwards each positive i_clk and signaling when reaching 0.
   Can be set in two modes: One shot or continuous mode. 
   We are following the MOS 65xx protocol so i_cs must be LOW and i_clk HIGH 
   to force reading in i_mode and i_value. */

module counter( input reg i_clk,
                input reg i_reset,
                input reg i_cs,
                input CounterMode i_mode,   // SINGLE_SHOT, CONTINUOUS
                input reg [15:0] i_value,
                output reg o_irq);

  reg[15:0] startValue;
  CounterMode mode;

  reg[15:0] currentValue;

  CounterState state;
  CounterState nextState;

  always_ff @(posedge i_clk or negedge i_reset) begin
    state<=nextState;
    if (!i_reset) begin
      startValue<=0;
      mode<=CONTINUOUS;
      currentValue<=0;
      state<=csIdle;
    end    
    else begin
      if (!i_cs) begin
        startValue<=i_value;
        currentValue<=i_value;
        mode<=i_mode;
        state<=csIdle;
      end
      else
        if (nextState==csAlarm) currentValue<= mode==CONTINUOUS ? startValue : 0;
        else if (nextState==csCounting) currentValue<=currentValue-1;    
      end
  end
  
  always_comb begin
    nextState=csCounting;
    case (state)
      csIdle, csAlarm: begin 
        if (currentValue==0) nextState=csIdle;
      end
      csCounting: begin
        if (currentValue<=1) nextState=csAlarm;
      end
    endcase
  end

  /* Output */
  always_ff @(posedge i_clk) begin
    o_irq= nextState==csAlarm;
  end
endmodule

`endif