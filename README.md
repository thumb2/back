Forth language and environment for Mickey Board, a custom BLE keyboard PCBA based on nRF51822.

Due to license limit, the "C" part of the Mickey Board firmware is not opensource. To make it more cusomizable and smart, BACK is coming. It's a STC (subroutine threaded code) forth implementation to make Mickey Board (nRF51822 based BLE keyboard) interactive and compilable with itself and a simple program like notepad. User can define and execute new words just like using a Forth environment on PC, to implement Macro or inquire&modify parameters, without firmware update. The whole environment is inside the keyboard, itself is also the input device and the PC is only an output device,

The BACK is written in assembly and forth-like language. After assembled by GNU AS, a hex file will be generated and put together with the Mickey Board firmware.

Add a hash filed in the diction header to speed up "find" process. The assembly part's hash fields are calculated by an elisp function.

Currently, some "words" work in Keil simulation environment and it has not been tested on the board.

Simulation code and on-board code are merged into one repo.

# proj_sim
Keil project for simulation purpose.

# proj_mb
GNU make project for Mickey Board.

