`ifndef MEMCTRL_H
`define MEMCTRL_H

typedef enum  {
  stateXXX,
  stateReset,
  delayAfterReset,
  enableClock,
  sendQPIEnable,
  stateIdle,
  sendQPIWriteCmd,
  sendQPIAddress,
  waitCycles,
  writeData,
  sendQPIReadCmd,
  readData
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

typedef enum logic[6:0] {
  ratPwrUp=0,
  ratInitialize=1,
  ratIdle=2,
  ratSendCommand=4,
  ratSendData=8,
  ratReadData=16,
  ratWaitCycle=32
} RamAccessType;


`endif 