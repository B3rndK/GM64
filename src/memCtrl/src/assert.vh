// SPDX-License-Identifier: MIT
// Copyright (C)2024, 2025 Bernd Krekeler, Herne, Germany

`ifndef ASSERT_VH
`define ASSERT_VH

integer failedAssertions=0;
`define FINAL_REPORT()  begin if (failedAssertions>0) begin \
            $display("░▒▓████████▓▒░  ░▒▓██████▓▒░  ░▒▓█▓▒░ ░▒▓█▓▒░        ░▒▓████████▓▒░ ░▒▓███████▓▒░"); \
            $display("░▒▓████████▓▒░  ░▒▓██████▓▒░  ░▒▓█▓▒░ ░▒▓█▓▒░        ░▒▓████████▓▒░ ░▒▓███████▓▒░"); \
            $display("░▒▓█▓▒░        ░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░ ░▒▓█▓▒░        ░▒▓█▓▒░        ░▒▓█▓▒░░▒▓█▓▒░"); \
            $display("░▒▓█▓▒░        ░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░ ░▒▓█▓▒░        ░▒▓█▓▒░        ░▒▓█▓▒░░▒▓█▓▒░"); \
            $display("░▒▓██████▓▒░   ░▒▓████████▓▒░ ░▒▓█▓▒░ ░▒▓█▓▒░        ░▒▓██████▓▒░   ░▒▓█▓▒░░▒▓█▓▒░"); \
            $display("░▒▓█▓▒░        ░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░ ░▒▓█▓▒░        ░▒▓█▓▒░        ░▒▓█▓▒░░▒▓█▓▒░"); \
            $display("░▒▓█▓▒░        ░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░ ░▒▓█▓▒░        ░▒▓█▓▒░        ░▒▓█▓▒░░▒▓█▓▒░"); \
            $display("░▒▓█▓▒░        ░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░ ░▒▓████████▓▒░ ░▒▓████████▓▒░ ░▒▓███████▓▒░"); \
            $display("Testbench indicates unit not OK. We spotted %0d critical situations.", failedAssertions); \
            end \
            else begin \
            $display("███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗"); \
            $display("██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝"); \
            $display("███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗"); \
            $display("╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║"); \
            $display("███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║"); \
            $display("╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝"); \
            $display("Testbench indicates unit OK."); \
            end \
            end             
`define ASSERT(c, title="Assertion failed:", a=`__LINE__, b=`__FILE__)    if (!c) begin $display("%s File: '%s' at line %0d", title, b, a); failedAssertions++; end; 

`endif