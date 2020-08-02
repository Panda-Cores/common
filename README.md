# Common

A collection of common components for the Panda cores

# List of components
* Wishbone interconnect
  * Multi-master/multi-slave
  * Masters selected by priority list
  * Memory mapped slaves
  * Masters can lock the bus to prevent high priority masters to interrupt them
* Load-Store-Unit
  * Connected to a wishbone interface as master
* Debug module
  * Not RISC-V spec consistent but rather a simple interface to access the memory and halt the core
  * Wishbone master (suggestion: highest priority master)
  * Possible commands:
    * Read memory location
    * Write memory location
    * Halt the core
    * Resume the core
    * Reset the core
    * Reset peripherals
    * Reset everything
