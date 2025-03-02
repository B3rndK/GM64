// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

// For easier reading
typedef enum bit[11:0] {
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

typedef struct packed  {  // Going from highest bit (18) to lowest bit (0)
  logic [5:0] ledNo;      // led to switch (1-64) 
  Color color;            // color to choose rgb (4:4:4)
  logic status;           // 0- off, 1- on
} debugInfo_t;
