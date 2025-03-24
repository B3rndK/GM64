// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany
`ifndef VISUMON_H
`define VISUMON_H

// For easier reading
typedef enum bit[11:0] {
  Black=12'b000000000000,
  AlmostBlack=12'b001000100010, // used as inactive color
  DarkRed=12'b011100010001,
  Red=12'b111100000000,
  DarkGreen=12'b000101110001,
  Green=12'b000011110000,
  DarkBlue=12'b000100010111,
  Blue=12'b000000001111,
  DarkGray=12'b001100110011,
  Gray=12'b011101110111,
  Yellow=12'b111111110000,  
  Magenta=12'b001100000011,
  Purple=12'b011100110111,
  White=12'b111111111111
} Color;

typedef struct packed  {  // Going from highest bit ledNo (18) to lowest bit status (0)
  logic [5:0] ledNo;      // Bit 13-18, led to switch (1-64) 
  Color color;            // Bit 1-12, color to choose rgb (4:4:4)
  logic status;           // Bit 0,  0- off, 1- on
} debugInfo_t;

`endif