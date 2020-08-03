# Common

# !!!This repository is split up in multiple repos for each module and is no longer maintained!!!

A collection of common components for the Panda cores

# List of components
* Wishbone interconnect
* Load-Store-Unit
* Debug module
  * Not RISC-V spec consistent but rather a simple interface
  * Two modules
    * Main module can access memory and can reset the core/peripherals
    * Core module can access registers, PC and can halt the core
  * Main module forwards command to core module
