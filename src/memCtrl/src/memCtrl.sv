// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

`include "memCtrl.vh"

/* 24-bit address, 8-Bit memory controller interface using 2x LY68S3200 
   32M (4Mx8) Bits Serial Pseudo-SRAM with QPI divided into 2 banks. */

module memCtrl( input logic i_clkRAM,  // RAM clock (100Mhz)
                input logic reset,
                input logic i_cs,    // 0-enable
                input logic i_write, // 0-read, 1-write
                input logic [23:0] i_address, // 24-bit address
                input logic i_bank, // 0- U7, 1- U9
                output wire o_psram_sclk,                
                input  logic [7:0] i_dataToWrite,
                output logic [7:0] o_dataRead,
                inout wire io_psram_data0,
                inout wire io_psram_data1,
                inout wire io_psram_data2,
                inout wire io_psram_data3,
                inout wire io_psram_data4,                
                inout wire io_psram_data5,
                inout wire io_psram_data6,
                inout wire io_psram_data7,            
                output wire o_psram_cs,
                output logic o_busy, // 1-Busy
                output logic o_dataReady,
                output StateMachine o_state); // 1-ready

  parameter initDelayInClkCyles=15000; // 150us @ 100Mhz
  
  reg [3:0] dataU7; // Bank 0
  reg [3:0] dataU9; // Bank 1
  reg [7:0] qpiCommand;


  logic [7:0] dataRead;

  Action action;
  logic stopClock;
  // Use for debugging purposes only
  //logic led;
  //assign o_led=!led;

  reg [23:0] address;
  logic [15:0] delayCounter;
  StateMachine next;
   
  reg [7:0] byteToWrite;
  reg psram_cs;
    
  reg[5:0] shifter;
 
  assign o_psram_sclk= stopClock ? 0 : i_clkRAM;

  reg [7:0] direction;
  logic isInitialized=0;

  assign io_psram_data0=(direction[0]==1 ? dataU7[0] : 1'bZ);
  assign io_psram_data1=(direction[1]==1 ? dataU7[1] : 1'bZ);
  assign io_psram_data2=(direction[2]==1 ? dataU7[2] : 1'bZ);
  assign io_psram_data3=(direction[3]==1 ? dataU7[3] : 1'bZ);

  assign io_psram_data4=(direction[4]==1 ? dataU9[0] : 1'bZ);
  assign io_psram_data5=(direction[5]==1 ? dataU9[1] : 1'bZ);
  assign io_psram_data6=(direction[6]==1 ? dataU9[2] : 1'bZ);
  assign io_psram_data7=(direction[7]==1 ? dataU9[3] : 1'bZ);
 
  logic bankToUse;
  assign o_psram_cs= psram_cs;

  // State logic
  always_ff @(posedge i_clkRAM or negedge reset) 
    if (!reset) o_state<=stateReset;
    else o_state<=next;  

  // Next logic
  always_comb begin
    case (o_state)
      stateXXX:               begin                                
                                next=stateReset;
                              end

      stateReset:             next=delayAfterReset;

      delayAfterReset:
        if (delayCounter==0) begin
          if (!isInitialized) next=sendQPIEnable;
          else                next=stateIdle;
        end
        else                  next=delayAfterReset;        
  
      sendQPIEnable:      
      if (shifter==8)       next=stateIdle;
      else                  next=sendQPIEnable;
  
      stateIdle: begin
        case (action)
          DONOTHING:          next=stateIdle;
          DOWRITE:            next=sendQPIWriteCmd;
          DOREAD:             next=sendQPIReadCmd;
          default:            next=stateIdle;
        endcase
      end
      
      sendQPIWriteCmd:
        if (shifter==2)         next=sendQPIAddress;
        else                    next=sendQPIWriteCmd;
      
      sendQPIReadCmd:
        if (shifter==2)         next=sendQPIAddress;
        else                    next=sendQPIReadCmd;

      sendQPIAddress:
        if (shifter==8)
        begin
          if (action==DOWRITE)  next=writeData;
          else                  next=waitCycles;
        end
        else                    next=sendQPIAddress;

      waitCycles:               next=readData;

      readData:
        if (shifter>='h11)      next=stateIdle;
        else                    next=readData;

      writeData:
        if (shifter==10)        next=stateIdle;
        else                    next=writeData;

      default:                  next=stateXXX;
    endcase
  end
  
// input/output logic
always_comb begin 
  if (!i_cs && next==stateIdle) begin
    bankToUse=i_bank;
    address=i_address;
    if (i_write==1) begin
      byteToWrite=i_dataToWrite;
      action=DOWRITE;      
    end
    else action=DOREAD;
  end
  else
    psram_cs=0;
    case (next)
      stateReset,
      delayAfterReset:
                        begin
                          action=DONOTHING;
                          psram_cs=1;
                          direction[7:0]=8'b11111111;
                        end          

      sendQPIEnable:    direction[7:0]=8'b00010001;

      writeData,
      readData,
      sendQPIWriteCmd,
      sendQPIReadCmd,
      sendQPIAddress:   if (bankToUse==0) direction[7:0]=8'b00001111;
                        else direction[7:0]=8'b11110000;

      waitCycles:     direction[7:0]=8'b00000000;
                
      stateIdle:          begin
                            action=DONOTHING;
                            direction[7:0]=8'b00000000;
                            psram_cs=1;
                        end          

      default:          begin
                            direction[7:0]=8'b00000000;
                            psram_cs=1;
                        end                          
    endcase
  end
  
  always_ff @(posedge i_clkRAM or negedge reset) begin
    if (!reset) begin
      isInitialized<=0;
      delayCounter<=0;
      dataRead<=0;
      shifter<=0;
      o_dataReady<=0;
      qpiCommand<=0;
      o_busy<=1;
      dataU7[3:0]<=4'b0;
      dataU9[3:0]<=4'b0;
      stopClock<=1;
    end
    else begin
      o_busy<=(next!=stateIdle);
      case (next) 
        stateReset: begin
          delayCounter<=initDelayInClkCyles;
        end

        delayAfterReset: begin 
          qpiCommand<=enableQPIModeCmd;
          delayCounter<=delayCounter-1;
          if (delayCounter==3) stopClock<=0;
        end

        sendQPIEnable: begin
          dataU7[0]<=qpiCommand[shifter^7];
          dataU9[0]<=qpiCommand[shifter^7];
          shifter<=shifter+1;        
          isInitialized<=1;
        end    

        stateIdle: begin
          o_dataReady<=0;
          shifter<=0;  
          if (action!=DONOTHING) begin
            if (i_write==1) qpiCommand<=SPIQuadWrite;                  
            else qpiCommand<=SPIQuadRead;
            o_busy<=1;
          end
        end

        sendQPIWriteCmd: begin
          if (bankToUse==0) begin
            if (shifter==0) begin
              dataU7[3:0]<=4'h3;
            end
            else begin
              dataU7[3:0]<=4'h8;
            end
          end
          else begin
            if (shifter==0) begin
              dataU9[3:0]<=4'h03;
            end
            else begin
              dataU9[3:0]<=4'h08;
            end
          end
          shifter<=shifter+1; 
        end

        sendQPIReadCmd: begin     
          qpiCommand<=SPIQuadRead;
          if (bankToUse==0) begin
            if (shifter==0) begin
              dataU7[3:0]<=4'h0e;
            end
            else begin
              dataU7[3:0]<=4'h0b;
            end
          end
          else begin
            if (shifter==0) begin
              dataU9[3:0]<=4'h0e;
            end
            else begin
              dataU9[3:0]<=4'h0b;
            end
          end
          shifter<=shifter+1; 
        end

        sendQPIAddress: begin
          if (bankToUse==0) begin
            case (shifter) 
              2: dataU7[3:0]<=address[23:20];
              3: dataU7[3:0]<=address[19:16];
              4: dataU7[3:0]<=address[15:12];
              5: dataU7[3:0]<=address[11:8];
              6: dataU7[3:0]<=address[7:4];
              7: dataU7[3:0]<=address[3:0];
            endcase
          end
          else begin
            case (shifter) 
              2: dataU9[3:0]<=address[23:20];
              3: dataU9[3:0]<=address[19:16];
              4: dataU9[3:0]<=address[15:12];      
              5: dataU9[3:0]<=address[11:8];
              6: dataU9[3:0]<=address[7:4];
              7: dataU9[3:0]<=address[3:0];
            endcase
          end
          shifter<=shifter+1;        
        end

        writeData: begin
          case (shifter) 
            8: if (bankToUse==0) dataU7[3:0]<=byteToWrite[7:4];
               else dataU9[3:0]<=byteToWrite[7:4];      
            9: begin 
                  if (bankToUse==0) dataU7[3:0]<=byteToWrite[3:0];
                  else dataU9[3:0]<=byteToWrite[3:0];
               end
          endcase
          shifter<=shifter+1; 
        end
      
        /* We have to wait for the psram to fetch our data before we can
            actually read after having sent the address. */
        readData: begin
          // shifter is 8 here
          case (shifter) 
            'h0f: begin
                  if (bankToUse==0) begin
                    o_dataRead[4]<=io_psram_data0;
                    o_dataRead[5]<=io_psram_data1;
                    o_dataRead[6]<=io_psram_data2;
                    o_dataRead[7]<=io_psram_data3;
                  end
                  else begin
                    o_dataRead[4]<=io_psram_data4;
                    o_dataRead[5]<=io_psram_data5;
                    o_dataRead[6]<=io_psram_data6;
                    o_dataRead[7]<=io_psram_data7;
                  end
                end  
            'h10: begin
                  if (bankToUse==0) begin
                    o_dataRead[0]<=io_psram_data0;
                    o_dataRead[1]<=io_psram_data1;
                    o_dataRead[2]<=io_psram_data2;
                    o_dataRead[3]<=io_psram_data3;
                  end
                  else begin
                    o_dataRead[0]<=io_psram_data4;
                    o_dataRead[1]<=io_psram_data5;
                    o_dataRead[2]<=io_psram_data6;
                    o_dataRead[3]<=io_psram_data7;
                  end                                      
                  o_dataReady<=1;
                  o_busy<=0;
                end 

            default:  ;

          endcase
          shifter<=shifter+1;               
        end
        default: ;        
      endcase 
    end
  end
endmodule



  
  
