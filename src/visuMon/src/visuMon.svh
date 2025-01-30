// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

typedef struct packed  { // Going from highest bit (18) to lowest bit (0)
  logic [6:0] ledNo;     // led to switch (1-64) 
  logic [11:0] color;    // color to choose rgb (4:4:4)
  logic status;          // 0- off, 1- on
} debugInfo_t;

// For easier reading
typedef enum bit[11:0] {
  almostBlack=12'b001000100010, // used as inactive color
  darkRed=12'b011100010001,
  red=12'b111100000000,
  darkGreen=12'b000101110001,
  green=12'b000011110000,
  darkBlue=12'b000100010111,
  blue=12'b000000001111,
  darkGray=12'b001100110011,
  gray=12'b011101110111,
  yellow=12'b111111110000,  
  magenta=12'b001100000011,
  purple=12'b011100110111,
  white=12'b111111111111
} Color;

