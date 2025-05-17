`ifndef MEMCTRL_H
`define MEMCTRL_H

`define LOW   1'b0;
`define HIGH  1'b1;

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

typedef enum logic [7:0] {
  enableQPIModeCmd=8'b00110101,
  SPIQuadWrite=8'b00111000, // 3,8    
  SPIQuadRead=8'b11101011 // E,B
} QPICommands;

typedef enum bit {
  READ,
  WRITE
} Direction;

typedef enum bit[1:0]  {
  DONOTHING,
  DOREAD,
  DOWRITE,
  XXX
} Action;

`endif 