# GM64
Rebuilding a C64 using a Cologne Chip GateMate(R) FPGA development board by Olimex. Please see https://www.olimex.com/Products/FPGA/GateMate/GateMateA1-EVB/open-source-hardware

## Intention
Just like my C64 emulation project on the RP2040 using the Olimex Neo6502 minicomputer (https://github.com/B3rndK/C64Neo6502), this project is for fun. I always wanted to do some chip design like the ancestors for the Commodore C64 or the Commodore Amiga.
Now that FPGA technology and the required design software came down from several hundred thousand Euros to about fifty Euros, this goal came into reach. It is both fun and education because I did not work on a bigger FPGA based project before.

## Project status 
The project has just started. 

## Dependencies
I am using:

* Cologne Chip's GateMate&trade; SDK 
* [Yosys Open Synthesis Suite](https://yosyshq.net/yosys)
* [Icarus Verilog](https://steveicarus.github.io/iverilog)
* [GTKWave Wave Viewer](https://gtkwave.sourceforge.net)
* [6502 Verilog HDL model by Arlet Ottens](https://github.com/Arlet/verilog-6502)
* [Microsoft Visual Studio Code](https://code.visualstudio.com)
* [Gnu Make 4.3](http://gnu.org)
* [Ubuntu Linux](https://ubuntu.com)
    
## Hardware

* GateMate&trade; FPGA from [Cologne Chip](https://www.colognechip.com/programmable-logic/gatemate/) CCGM1A1 on the [Olimex development board](https://www.olimex.com/Products/FPGA/GateMate/GateMateA1-EVB/open-source-hardware).
* A cheap (~€16) video capture USB stick to display the VGA output of the FPGA onto my HDMI monitor in a window using [Gucview](https://guvcview.sourceforge.net/)

## References
Thanks to Steven Hugg's excellent [ide website](https://8bitworkshop.com/).

### Can't wait and want to experience the things to come right now?
In the meantime check out my [C64 emulation](https://github.com/B3rndK/C64Neo6502) on the [Olimex RP2040 based Neo6502 retro computer](https://www.olimex.com/Products/Retro-Computers/Neo6502/open-source-hardware). It is my software emulation written in C++ of the C64. This was a kind of finger excercise / blueprint for this project.
