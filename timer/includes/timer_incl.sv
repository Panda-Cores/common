// ------------------------ Disclaimer -----------------------
// No warranty of correctness, synthesizability or 
// functionality of this code is given.
// Use this code under your own risk.
// When using this code, copy this disclaimer at the top of 
// your file
//
// (c) Panda Cores 2020
//
// ------------------------------------------------------------
//
// Module name: timer_inc.sv
//
// Authors: Luca Hanel
// 
// Functionality: defines the bits and such for the timer module
//
// TODO: 
//
// ------------------------------------------------------------

`define TIMER 0
`define CFG 1

// Compare value, in order to trigger interrupts
`define CMP 2

// 4 bit prescaler (increment is left shifted by prescaler value)
`define PRSC_START 11
`define PRSC_END   8

// Enable bit
`define ENABLE_BIT 0