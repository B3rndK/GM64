// SPDX-License-Identifier: MIT
// Copyright (C)2024 Bernd Krekeler, Herne, Germany

`ifndef MEMCTRL_H
`define MEMCTRL_H

/* Memory controller interface, independent of memory type or speed. */

module memCtrl(input            clk,
               input            reset,
               input            CE,    // 1-enable, 0-Z 
               input            write, // 0-read, 1-write
               input  [15:0]    adress,
               input  [3:0]     numberOfBytesToWrite,
               input  [15*7:0]  dataToWrite,
               output [7:0]     dataRead,
               output           busy); // 1-busy


endmodule

`endif