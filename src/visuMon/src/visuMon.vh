// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

typedef struct packed {

  logic [5:0] ledNo;    // led to switch (1-64)
  logic [11:0] rgb;     // color to choose (4:4:4)
  logic [1:0] status;    // 0- off, 1- on

} debugInfo;

