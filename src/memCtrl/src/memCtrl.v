// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef MEMCTRL_H
`define MEMCTRL_H

/* Memory controller interface
   Supports concurrent access by clk that is, clock low = channel 1, 
   clock high= channel 2*/

typedef enum {
  stateReset=0,
  stateInit_1=1,
  stateInit_2=2,
  stateEnableQPI=3,
  stateIdle=4,
  stateRead_1=5
} StateMachine;

typedef enum bit[7:0] {
  enableQPIMode=8'h35
} QPICommands;

module memCtrl( input            clk,
                input            reset,
                input            CE,    // 1-enable, 0-Z 
                input            write, // 0-read, 1-write
                input reg [6:0]  bank, // bank 0-63 forming a total of 4096KB
                input reg [15:0] addrBus,
                input reg [3:0]  numberOfBytesToWrite,
                input reg [15*7:0] dataToWrite,
                output reg [7:0]   dataRead,
                inout  wire io_psram_data0,
                inout  wire io_psram_data1,
                inout  wire io_psram_data2,
                inout  wire io_psram_data3,
                inout  wire io_psram_data4,
                inout  wire io_psram_data5,
                inout  wire io_psram_data6,
                inout  wire io_psram_data7,            
                output wire o_psram_cs,
                output wire o_psram_sclk,
                output wire busy); // 1-busy
  
   
  reg dataU7[3:0];
  reg dataU9[3:0];

  assign  io_psram_data0=dataU7[0];
  assign  io_psram_data1=dataU7[1];
  assign  io_psram_data2=dataU7[2];
  assign  io_psram_data3=dataU7[3];
  assign  io_psram_data4=dataU9[0];
  assign  io_psram_data5=dataU9[1];
  assign  io_psram_data6=dataU9[2];
  assign  io_psram_data7=dataU9[3];         

  reg isBusy;

  reg [15:0] address;
  
  parameter LOW=1'b0;
  parameter HIGH=1'b1;
 
  parameter initDelayInClkCyles=15000; // 150us @100Mhz
  shortint delayCounter;
 
  wire CS;

  reg [5:0] state;
  
  reg [7:0] qpiCmd;

  reg memCtrlCE;
  
  assign busy=isBusy;
  reg psram_cs;
  assign o_psram_cs=psram_cs;

  shortint shifter;
  
  reg psram_sclk;
  assign o_psram_sclk=psram_sclk;
  
  always @(clk)
  begin
    if (delayCounter>0) delayCounter--;
    if (state>stateEnableQPI) psram_sclk=clk;
  end

  always @(posedge clk or posedge reset)  // e.g. PHI0
  begin
    if (reset) begin
      state=stateReset;
      delayCounter=initDelayInClkCyles;
    end
    else begin
      ;
    end
  end

  /* We will allow concurrent access on odd/even cycles later on */

  always @(negedge clk or posedge reset) // e.g. VICII
  begin
    if (reset) begin
      ;
    end
    else begin
      ;
    end
  end
  
  always @(posedge clk) begin
    case (state)
      stateReset: begin
        // Initialization, should be kept low for 150us (10ns per clock~ 150*1000/10 clks)
        psram_cs=HIGH;
        isBusy=1;
        
        // U7
        dataU7[0]=LOW;
        dataU7[1]=LOW;
        dataU7[2]=LOW;
        dataU7[3]=LOW;
        
        // U9
        dataU9[0]=LOW;
        dataU9[1]=LOW;
        dataU9[2]=LOW;
        dataU9[3]=LOW;
       
        state=stateInit_1;
      end

      stateInit_1: begin
        psram_sclk=LOW;
        if (delayCounter==0) begin
          psram_sclk=HIGH;
          state=stateInit_2;
        end
      end

      stateInit_2: begin // Enable QPI mode
        psram_sclk=LOW;
        shifter=0;
        state=stateEnableQPI;
      end

      stateEnableQPI: begin // Enable QPI mode
        case (shifter)
          0: begin
            psram_cs=LOW;
            dataU7[0]=enableQPIMode[7];    
            dataU7[1]='z;
            dataU9[0]=enableQPIMode[7];
            dataU9[1]='z;
          end
          1: begin
            dataU7[0]=enableQPIMode[6];    
            dataU9[0]=enableQPIMode[6];
          end
          2: begin
            dataU7[0]=enableQPIMode[5];    
            dataU9[0]=enableQPIMode[5];
          end
          3: begin
            dataU7[0]=enableQPIMode[4];    
            dataU9[0]=enableQPIMode[4];
          end
          4: begin
            dataU7[0]=enableQPIMode[3];    
            dataU9[0]=enableQPIMode[3];
          end
          5: begin
            dataU7[0]=enableQPIMode[2];    
            dataU9[0]=enableQPIMode[2];
          end
          6: begin
            dataU7[0]=enableQPIMode[1];    
            dataU9[0]=enableQPIMode[1];
          end
          7: begin
            dataU7[0]=enableQPIMode[0];    
            dataU9[0]=enableQPIMode[0];
            psram_cs=HIGH;
          end
        endcase
        shifter++;
      end

      stateIdle: begin
        isBusy=0;
        if (CE) begin
          isBusy=1;
          address=addrBus;
          if (!write) begin
            state=stateRead_1;
          end
        end
      end
      
      stateRead_1: begin
        qpiCmd=enableQPIMode;
        //io_psram_data0
      end

      default:
        ;
    endcase
  end


endmodule

`endif