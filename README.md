# RISC-V BMP Animator

## Overview
This project is a RISC-V assembly program that loads, displays, and animates two uncompressed BMP images. It utilizes a memory-mapped bitmap display (512x512 resolution) and features a horizontal sliding transition animation between the two provided images.

## Architecture and File Details
The project is divided into modular files to separate I/O operations from rendering and application logic.

* **`main.s` (Application Logic & Animation):**
  Manages the main execution flow, animation loop, and image swapping.
  * *Why it is optimal:* It calculates the static centering offsets (`cx`, `cy`) only once at the program's start. During the swap phase, it performs an in-memory swap of the image structures (pointers and dimensions) rather than reloading the files from the disk, drastically reducing I/O overhead. Uses `SYS_SLEEP` instead of busy-wait loops, freeing CPU cycles.

* **`bmp.s` (File I/O & Parsing):**
  Responsible for opening files, parsing the 54-byte BMP header, and loading pixel data.
  * *Why it is optimal:* Instead of statically allocating large memory buffers in `.data`, it uses dynamic memory allocation (`SYS_SBRK`) to reserve exactly the amount of heap space required based on the parsed width and height. Row stride calculation uses efficient bitwise arithmetic (`andi a0, t1, -4`) to achieve 4-byte alignment without division or modulo operations.

* **`display.s` (Rendering Engine):**
  Draws the dynamically loaded pixel data to the simulated memory-mapped display.
  * *Why it is optimal:* Heavily relies on bitwise shifts instead of expensive multiplication instructions. For example, calculating the screen address uses `slli` (shift left logical) by 9 (multiplying by 512) and by 2 (multiplying by 4 bytes per pixel). It implements strict boundary clipping (`bltz`, `bge`), discarding out-of-bounds pixels immediately to prevent memory corruption and save rendering cycles. BGR to RGB conversion is done efficiently in registers using bitwise shifts and ORs.

* **`syscalls.s` (Environment Definitions):**
  A header file defining environment system calls, screen dimensions, and BMP header parameters using `.eqv`. This ensures magic numbers are not hardcoded throughout the logic.

## Requirements
* RARS (RISC-V Assembler and Runtime Simulator)

## Usage Instructions
1. Open RARS simulator.
2. Navigate to the `Tools` menu and select `Bitmap Display`.
3. Configure the Bitmap Display with the following settings:
   * Unit Width in Pixels: 1
   * Unit Height in Pixels: 1
   * Display Width in Pixels: 512
   * Display Height in Pixels: 512
   * Base Address for Display: `0x10040000`
4. Click `Connect to MIPS`.
5. Ensure `main.s` is the active file.
6. Assemble the program.
7. In the run settings, provide the paths to two valid uncompressed BMP files as program arguments.
8. Run the simulation.
README-v2.md
Wyświetlam README-v2.md.