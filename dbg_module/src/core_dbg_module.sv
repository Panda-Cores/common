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
// Module name: core_dbg_module
//
// Authors: Luca Hanel
// 
// Functionality: 
//
// Commands:
//
// TODO:      Read & write register file
//            Read (and maybe write for IF) inter-stage pc & instr
//
// ------------------------------------------------------------

module core_dbg_module #(
  parameter INTERNAL_MEM_S = 32
)(
  input logic               clk,
  input logic               rstn_i,
  output logic [4:0]        reg_sel_o,
  input logic [31:0]        data_reg_i,
  dbg_intf.dut              dbg_intf
);



endmodule