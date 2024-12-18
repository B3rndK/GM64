// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef MEMCTRL_H
`define MEMCTRL_H

/* 8-Bit Memory controller interface using LY68S3200 
   32M (4Mx8) Bits Serial Pseudo-SRAM with SPI and QPI. */

typedef enum bit[7:0] {
  stateReset=0,
  delayAfterReset=1,
  sendQPIEnable=3,
  stateIdle=10,
  sendQPIWriteCmd=11,
  
  sendQPIAddress=12,
  writeData=20,

  sendQPIReadCommand=60,
  readData=61,

  waitCycle=80,

  stateXXX=92
 
} StateMachine;

typedef enum reg[7:0] {
  enableQPIModeCmd=8'b00110101,
  SPIQuadWrite=8'b00111000,
  SPIQuadRead=8'heb
} QPICommands;

typedef enum reg  {
  READ=0,
  WRITE=1
} Direction;

typedef enum bit[1:0]  {
  DONOTHING=0,
  DOREAD=1,
  DOWRITE=2,
  XXX=3
} Action;


module memCtrl( input wire i_clkRAM,  // RAM clock (100Mhz)
                input wire reset,
                input wire i_cs,    // 0-enable
                input wire i_write, // 0-read, 1-write
                input wire [23:0] i_address, // 24-bit address
                output wire o_psram_sclk,                
                input wire [7:0] dataToWrite,
                output wire [7:0] dataRead,
                inout wire io_psram_data0,
                inout wire io_psram_data1,
                inout wire io_psram_data2,
                inout wire io_psram_data3,
                inout wire io_psram_data4,                
                inout wire io_psram_data5,
                inout wire io_psram_data6,
                inout wire io_psram_data7,            
                output wire o_psram_cs,
                output wire oBusy, // 1-Busy
                output wire o_dataReady); 

  reg [3:0] dataU7;
  reg [3:0] dataBufferU7;
  
  reg [3:0] dataU9;
  reg [3:0] dataBufferU9;

  reg isWrite;
  reg [7:0] qpiCommand;

  /* Output */
  reg n_oBusy;
  assign oBusy=n_oBusy;

  Action action;

reg mycs;
reg myirq;  


//  assign  dataRead[0]=dataReady ? byteToRead[0] : 1'bZ;
//  assign  dataRead[1]=dataReady ? byteToRead[1] : 1'bZ; 
//  assign  dataRead[2]=dataReady ? byteToRead[2] : 1'bZ; 
//  assign  dataRead[3]=dataReady ? byteToRead[3] : 1'bZ; 
//  assign  dataRead[4]=dataReady ? byteToRead[4] : 1'bZ; 
//  assign  dataRead[5]=dataReady ? byteToRead[5] : 1'bZ; 
//  assign  dataRead[6]=dataReady ? byteToRead[6] : 1'bZ; 
//  assign  dataRead[7]=dataReady ? byteToRead[7] : 1'bZ; 


  reg dataReady;        
  assign o_dataReady=dataReady;

  reg [23:0] address;
  


  // Loops through 3-0 to reuse write state, writing 4x same byte
  reg [3:0] byteToSendCounter;

  parameter LOW=1'b0;
  parameter HIGH=1'b1;
 
  integer initDelayInClkCyles=15000; // 150us @ 100Mhz
  integer delayCounter;
  
  StateMachine state, next;
    
  reg [7:0] byteToWrite;
  reg [7:0] byteToReadBuffer;
  reg [7:0] byteToRead;

  
  reg fetchData;

  reg psram_cs;
  assign o_psram_cs= psram_cs;
  
  reg[5:0] shifter;
 
  reg psram_sclk;
  assign o_psram_sclk=i_clkRAM;

  // Direction direction; // 0- in (read), 1-out (write)
  reg [7:0] direction;

  assign io_psram_data0=(direction[0]==1 ? dataU7[0] : 1'bZ);
  assign io_psram_data1=(direction[1]==1 ? dataU7[1] : 1'bZ);
  assign io_psram_data2=(direction[2]==1 ? dataU7[2] : 1'bZ);
  assign io_psram_data3=(direction[3]==1 ? dataU7[3] : 1'bZ);

  assign io_psram_data4=(direction[4]==1 ? dataU9[0] : 1'bZ);
  assign io_psram_data5=(direction[5]==1 ? dataU9[1] : 1'bZ);
  assign io_psram_data6=(direction[6]==1 ? dataU9[2] : 1'bZ);
  assign io_psram_data7=(direction[7]==1 ? dataU9[3] : 1'bZ);

  
  always_ff @(posedge i_clkRAM or negedge reset) 
    if (!reset) state<=stateXXX;
    else state<=next;  
  
  // next logic
  always_comb begin
    next=stateXXX;
    case (state)

      stateXXX:               next=stateReset;
      
      stateReset:
                              next=delayAfterReset;
      delayAfterReset:
        if (delayCounter==0)  next=sendQPIEnable;
        else                  next=delayAfterReset;        
      
      sendQPIEnable:      
        if (shifter==8)       next=stateIdle;
        else                  next=sendQPIEnable;
    
      stateIdle: begin
        case (action)
          DONOTHING:          next=stateIdle;
          DOWRITE:            next=sendQPIWriteCmd;
          DOREAD:             next=stateIdle;
          default:            next=stateIdle;
        endcase
      end
      
      sendQPIWriteCmd:
        if (shifter==8)         next=sendQPIAddress;
        else                    next=sendQPIWriteCmd;

      sendQPIAddress:
        if (shifter==14)
        begin
          if (action==DOWRITE)  next=writeData;
          else                  next=readData;
        end
        else
                                next=sendQPIAddress;
      readData:
        ;
      writeData:
        ;

    endcase
  end
  

  always_ff @(posedge i_clkRAM or negedge reset) begin

    n_oBusy<=1;
    dataU7<=4'bZ;
    dataU9<=4'bZ;
    psram_cs<=HIGH;
    direction<='0;
    
    if (!reset) begin
      ;
    end
    else begin
      if (i_cs==0) begin
        shifter<=0;
        if (i_write) begin
            action<=DOWRITE;
            qpiCommand<=SPIQuadWrite;
            byteToWrite<=dataToWrite;
        end
        else begin
          action<=DOREAD;
          qpiCommand<=SPIQuadRead;
        end
        address<=i_address;
      end
      else
        case (next) 
          stateReset: begin
            delayCounter<=initDelayInClkCyles;
          end

          delayAfterReset: begin 
            delayCounter<=delayCounter-1;
            qpiCommand<=enableQPIModeCmd;
            shifter<=0;
          end

          sendQPIEnable: begin
            psram_cs<=LOW;
            direction<=8'b00010001; // SI active only
            dataU7[0]<=qpiCommand[shifter^7];
            dataU9[0]<=qpiCommand[shifter^7];
            shifter<=shifter+1;        
          end    

          stateIdle: begin
            case (action)
              DOWRITE: begin
                qpiCommand<=SPIQuadWrite;
                shifter<=0;           
              end
              DOREAD: begin
                qpiCommand<=SPIQuadRead;
                shifter<=0;                                     
              end
              DONOTHING: 
                n_oBusy<=0;
            endcase
          end

          sendQPIWriteCmd: begin
            psram_cs<=LOW;
            direction<=8'b00010001; // SI active only
            dataU7[0]<=qpiCommand[shifter^7];
            dataU9[0]<=qpiCommand[shifter^7];        
            shifter<=shifter+1;        
          end

          sendQPIAddress: begin
            psram_cs<=LOW;
            direction<=8'hFF; // SI active only
            case (shifter) 
              9:  begin
                    dataU7[0]<=address[20];
                    dataU7[1]<=address[21];
                    dataU7[2]<=address[22];
                    dataU7[3]<=address[23];
                  end
              10:  begin
                    dataU7[0]<=address[16];
                    dataU7[1]<=address[17];
                    dataU7[2]<=address[18];
                    dataU7[3]<=address[19];
                  end
              11: begin
                    dataU7[0]<=address[12];
                    dataU7[1]<=address[13];
                    dataU7[2]<=address[14];
                    dataU7[3]<=address[15];
                  end
              12: begin
                    dataU7[0]<=address[8];
                    dataU7[1]<=address[9];
                    dataU7[2]<=address[10];
                    dataU7[3]<=address[11];
                  end
              13: begin
                    dataU7[0]<=address[4];
                    dataU7[1]<=address[5];
                    dataU7[2]<=address[6];
                    dataU7[3]<=address[7];
                  end
              14: begin
                    dataU7[0]<=address[0];
                    dataU7[1]<=address[1];
                    dataU7[2]<=address[2];
                    dataU7[3]<=address[3];
                    psram_cs<=HIGH;
                  end
            endcase
            shifter<=shifter+1;        
          end

          writeData: begin
            psram_cs<=LOW;
            direction<=8'hff;
            shifter<=shifter+1;        
          end


  /*      
          stateWrite_SendWriteCmd: begin
            
            direction[0]<=1;
            direction[4]<=1;
            psram_cs<=LOW;
            dataU7[0]<=qpiCommand[shifter-1];
            dataU9[0]<=qpiCommand[shifter-1];        
          end

          // Write 24-bit address

          stateWrite_SendAddr23_20: begin
            dataU7[0]<=address[20];
            dataU7[1]<=address[21];
            dataU7[2]<=address[22];
            dataU7[3]<=address[23];
          end

          stateWrite_SendAddr19_16: begin
            dataU7[0]<=address[16];
            dataU7[1]<=address[17];
            dataU7[2]<=address[18];
            dataU7[3]<=address[19];
          end

          stateWrite_SendAddr15_12: begin
            dataU7[0]<=address[12];
            dataU7[1]<=address[13];
            dataU7[2]<=address[14];
            dataU7[3]<=address[15];
          end

          stateWrite_SendAddr11_8: begin
            dataU7[0]<=address[8];
            dataU7[1]<=address[9];
            dataU7[2]<=address[10];
            dataU7[3]<=address[11];
          end

          stateWrite_SendAddr7_4: begin
            dataU7[0]<=address[4];
            dataU7[1]<=address[5];
            dataU7[2]<=address[6];
            dataU7[3]<=address[7];
          end

          stateWrite_SendAddr3_0: begin
            dataU7[0]<=address[0];
            dataU7[1]<=address[1];
            dataU7[2]<=address[2];
            dataU7[3]<=address[3];
          end
        */
        endcase
    end
 end

endmodule
`endif 


/*
  always_ff @(posedge i_clkRAM or negedge reset) begin
    if (!reset) begin
      state<=stateReset;
      shifter<=0;
      delayCounter<=initDelayInClkCyles;
      action<=DONOTHING;
    end    
    else begin
      if (!i_cs) begin
        address<=addrBus;
        byteToWrite<=dataToWrite;
        if (i_write) begin
          state<=stateWrite_SendWriteCmd;
          qpiCommand<=SPIQuadWrite;
          action<=DOWRITE;
          shifter<=7;
        end
        else begin
          state<=stateRead_SendReadCmd_1;
          qpiCommand<=SPIQuadRead;
          action<=DOREAD;
        end
      end
      else
        case (next)
          
          stateReset: begin
          end
    
          stateInit_1: begin
            delayCounter<=delayCounter-1;            
            qpiCommand<=enableQPIMode;
          end

          stateInit_2: begin
            shifter<=7;
          end
          
          stateEnableQPI: begin
            shifter<=shifter-1;
          end

          stateWrite_SendWriteCmd: begin
            shifter<=shifter-1;
          end

          stateWrite_SendAddr23_20: begin // [3]=23, [2]=22...
          end

        endcase
        state<=next;
      end
  end

  always_comb  begin
    next=stateXXX;
    dataBufferU7=3'b0;
    dataBufferU9=3'b0;
    qpiCommand=qpiCommand;
    address=address;
    
    case (state)

      stateReset: begin
        next=stateInit_1;
      end

      stateInit_1: begin
        if (delayCounter==1) next=stateInit_2;
        else next=stateInit_1;
      end

      stateInit_2: begin 
        next=stateEnableQPI;
      end

      stateEnableQPI: begin 
        if (shifter>0) begin
          next=stateEnableQPI;  
        end        
       end

      stateIdle: begin        
        if (action==DONOTHING) begin
          next=stateWrite_SendWriteCmd;
        end          
      end

      stateWrite_SendWriteCmd: begin
        if (shifter>0) begin
          next=stateWrite_SendWriteCmd;  
        end        
        else next=stateWrite_SendAddr23_20;
      end

      stateWrite_SendAddr23_20: begin
        next=stateRead_SendAddr19_16;
      end
      stateWrite_SendAddr19_16: begin
        next=stateRead_SendAddr15_12;
      end
      stateWrite_SendAddr15_12: begin
        next=stateRead_SendAddr11_8;
      end
      stateWrite_SendAddr11_8: begin
        next=stateRead_SendAddr7_4;
      end
      stateWrite_SendAddr7_4: begin
        next=stateRead_SendAddr3_0;
      end
      default: next=stateXXX; 

      default: begin
        if (state>=stateRead_SendReadCmd_1 && state<=stateRead_SendReadCmd_7) begin
          case (state)
            stateRead_SendReadCmd_1: dataU7[0]=SPIQuadRead[6];
            stateRead_SendReadCmd_2: dataU7[0]=SPIQuadRead[5];
            stateRead_SendReadCmd_3: dataU7[0]=SPIQuadRead[4];
            stateRead_SendReadCmd_4: dataU7[0]=SPIQuadRead[3];
            stateRead_SendReadCmd_5: dataU7[0]=SPIQuadRead[2];
            stateRead_SendReadCmd_6: dataU7[0]=SPIQuadRead[1];
            stateRead_SendReadCmd_7: dataU7[0]=SPIQuadRead[0];
          endcase
          next++;
        end 
        else if (state>=stateRead_SendAddr23_20 && state<=stateRead_SendAddr3_0) begin
          case (state)
            stateRead_SendAddr23_20: begin
              dataU7[0]=address[20];
              dataU7[1]=address[21];
              dataU7[2]=address[22];
              dataU7[3]=address[23];
            end

            stateRead_SendAddr19_16: begin
              dataU7[0]=address[16];
              dataU7[1]=address[17];
              dataU7[2]=address[18];
              dataU7[3]=address[19];
            end

            stateRead_SendAddr15_12: begin
              dataU7[0]=address[12];
              dataU7[1]=address[13];
              dataU7[2]=address[14];
              dataU7[3]=address[15];
            end

            stateRead_SendAddr11_8: begin
              dataU7[0]=address[8];
              dataU7[1]=address[9];
              dataU7[2]=address[10];
              dataU7[3]=address[11];
            end

            stateRead_SendAddr7_4: begin
              dataU7[0]=address[4];
              dataU7[1]=address[5];
              dataU7[2]=address[6];
              dataU7[3]=address[7];
            end

            stateRead_SendAddr3_0: begin
              dataU7[0]=address[0];
              dataU7[1]=address[1];
              dataU7[2]=address[2];
              dataU7[3]=address[3];
            end
          endcase
          next++;
        end
        else if (state>=stateRead7_4 && state<=stateRead3_0) begin
          case (state)
            stateRead7_4: begin
              byteToRead[4]=io_psram_data0;
              byteToRead[5]=io_psram_data1;
              byteToRead[6]=io_psram_data2;
              byteToRead[7]=io_psram_data3;
            end

            stateRead3_0: begin
              byteToRead[0]=io_psram_data0;
              byteToRead[1]=io_psram_data1;
              byteToRead[2]=io_psram_data2;
              byteToRead[3]=io_psram_data3;
              psram_cs=HIGH;
              next=stateIdle;
              n_oBusy=0;
              dataReady=1;
            end
          endcase
          if (state!=stateIdle) next++;
        end
        else if (state>=stateWrite_SendWriteCmd_1 && state<=stateWrite_SendWriteCmd_7) begin
          case (state)
            stateWrite_SendWriteCmd_1: dataU7[0]=SPIQuadWrite[6];
            stateWrite_SendWriteCmd_2: dataU7[0]=SPIQuadWrite[5];
            stateWrite_SendWriteCmd_3: dataU7[0]=SPIQuadWrite[4];
            stateWrite_SendWriteCmd_4: dataU7[0]=SPIQuadWrite[3];
            stateWrite_SendWriteCmd_5: dataU7[0]=SPIQuadWrite[2];
            stateWrite_SendWriteCmd_6: dataU7[0]=SPIQuadWrite[1];
            stateWrite_SendWriteCmd_7: dataU7[0]=SPIQuadWrite[0];
          endcase
          next++;
        end
        else if (state>=stateWrite_SendAddr23_20 && state<=stateWrite_SendAddr3_0) begin
          case (state)
            stateWrite_SendAddr23_20: begin
              dataU7[0]=address[20];
              dataU7[1]=address[21];
              dataU7[2]=address[22];
              dataU7[3]=address[23];
            end

            stateWrite_SendAddr19_16: begin
              dataU7[0]=address[16];
              dataU7[1]=address[17];
              dataU7[2]=address[18];
              dataU7[3]=address[19];
            end

            stateWrite_SendAddr15_12: begin
              dataU7[0]=address[12];
              dataU7[1]=address[13];
              dataU7[2]=address[14];
              dataU7[3]=address[15];
            end

            stateWrite_SendAddr11_8: begin
              dataU7[0]=address[8];
              dataU7[1]=address[9];
              dataU7[2]=address[10];
              dataU7[3]=address[11];
            end

            stateWrite_SendAddr7_4: begin
              dataU7[0]=address[4];
              dataU7[1]=address[5];
              dataU7[2]=address[6];
              dataU7[3]=address[7];
            end

            stateWrite_SendAddr3_0: begin
              dataU7[0]=address[0];
              dataU7[1]=address[1];
              dataU7[2]=address[2];
              dataU7[3]=address[3];
            end
          endcase
          next++;
        end
        else if (state>=stateWrite_SendData7_4 && state<=stateWrite_SendData3_0) begin
          case (state)
            stateWrite_SendData7_4: begin
              dataU7[0]=byteToWrite[4];
              dataU7[1]=byteToWrite[5];
              dataU7[2]=byteToWrite[6];
              dataU7[3]=byteToWrite[7];
              next++;
            end

            stateWrite_SendData3_0: begin
              dataU7[0]=byteToWrite[0];
              dataU7[1]=byteToWrite[1];
              dataU7[2]=byteToWrite[2];
              dataU7[3]=byteToWrite[3];
              psram_cs=HIGH;
              next=stateIdle;              
              n_oBusy=0;
            end
          endcase
        end
        else if (state>=stateRead_WaitCycle_1 && state<=stateRead_WaitCycle_7) begin
          direction=READ;
          next++;
        end
      end
      
    endcase
  end */
  
  
