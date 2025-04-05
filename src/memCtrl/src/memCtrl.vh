`ifndef MEMCTRL_H
`define MEMCTRL_H

typedef enum bit[7:0] {
  stateReset=0,
  delayAfterReset=1,
  sendQPIEnable=3,
  stateIdle=10,
  sendQPIWriteCmd=11,
  sendQPIAddress=12,
  writeData=20,
  sendQPIReadCmd=60,
  readData=61,
 
  stateXXX=92
} StateMachine;

typedef enum reg[7:0] {
  enableQPIModeCmd=8'b00110101,
  SPIQuadWrite=8'b00111000, // 38h, 2x io only
  SPIQuadRead=8'b11101011 // EB
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

typedef enum logic[2:0] {
  ratPwrUp=0,
  ratInitialize=1,
  ratIdle=2,
  ratSendCommand=3,
  ratSendData=4,
  ratReadData=5,
  ratWaitCycle=6
} RamAccessType;


localparam WAITCYCLES = 6;

`define LOW   1'b0;
`define HIGH  1'b1;

`endif 