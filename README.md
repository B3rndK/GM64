# GM64
Rebuilding the Commodore 64 using a [Cologne Chip GateMate&trade;](https://www.colognechip.com) [FPGA development board by Olimex](https://www.olimex.com/Products/FPGA/GateMate/GateMateA1-EVB/open-source-hardware). 

## Intention
Just like my [C64 emulation project](https://github.com/B3rndK/C64Neo6502) on the [RP2040](https://www.raspberrypi.com/documentation/microcontrollers/rp2040.html) chip used on the [Olimex Neo6502 retro computer](https://www.olimex.com/Products/Retro-Computers/Neo6502/open-source-hardware), this project is for fun. I always wanted to do some chip design myself like the ancestors did for the Commodore 64 or the Commodore Amiga.
Now that FPGA development boards and the design software came down from several hundred thousand to about fifty Euros, this goal is now in reach. It is also no longer necessary to use breadboards and kilometres of wire for this. For me it is both fun and education because I did not work on a bigger FPGA based project before nor did I had the chance to work using FPGAs in my current job.

## Project status 
The project has just started. The next steps are as follows:

- [x] Setting up the IDE and directory structure
- [x] Makefiles and scripts to compile and test each module individually
- [x] Creation and upload of the bitstream to FPGA
- [x] System wide "monostable multivibrator style" reset module
- [x] Basic video output
- [ ] LY68S3200 PSRAM (4Mx8) BUS controller (99% but still not really stable)
- [ ] 6502 loading/storing/executing code from PSRAM
- [ ] Video module accessing PSRAM
- [ ] ... much, much more...
  
## Dependencies
Software I am using:

* [Yosys Open Synthesis Suite](https://yosyshq.net/yosys)
* [Icarus Verilog](https://steveicarus.github.io/iverilog)
* [openFPGALoader](https://github.com/trabucayre/openFPGALoader)
* [GTKWave Wave Viewer](https://gtkwave.sourceforge.net)
* [Cologne Chip's GateMate&trade; SDK](https://www.colognechip.com/programmable-logic/gatemate/) 
* [6502 Verilog HDL model by Arlet Ottens](https://github.com/Arlet/verilog-6502)
* [Microsoft Visual Studio Code](https://code.visualstudio.com)
* [Gnu Make](https://www.gnu.org/software/make/)
* [Ubuntu Linux](https://ubuntu.com)
    
## Hardware
* GateMate&trade; FPGA from [Cologne Chip](https://www.colognechip.com/programmable-logic/gatemate/) CCGM1A1 on the [Olimex development board](https://www.olimex.com/Products/FPGA/GateMate/GateMateA1-EVB/open-source-hardware).
* A cheap (~€16) video capture USB stick to display the VGA output of the FPGA onto my HDMI monitor in an overlapping window using [Gucview](https://guvcview.sourceforge.net/) or simply use the camera app.
  <p><img src="https://github.com/B3rndK/GM64/assets/47975140/178d5aa9-a7b8-496d-859b-2568bc66423e" width="640"></p>(My IDE with some FPGA's video test output in Gucview)<br><br>
* RIGOL DS1202Z-E Oscilloscope
  
## References
Thanks to Steven Hugg's excellent [ide website](https://8bitworkshop.com/).

### Can't wait and want to experience the things to come right now?
In the meantime you may want to check out my [C64 emulation](https://github.com/B3rndK/C64Neo6502) on the [Olimex RP2040 based Neo6502 retro computer](https://www.olimex.com/Products/Retro-Computers/Neo6502/open-source-hardware). It is a software emulation of the C64 written in C++ which was a kind of finger excercise / blueprint to follow for this project as well.
