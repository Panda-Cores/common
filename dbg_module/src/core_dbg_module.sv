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

`include "dbg_intf.sv"

module core_dbg_module(
  input logic               clk,
  input logic               rstn_i,
  dbg_intf.dut              dbg_bus,
  output logic              halt_core_o,
  output logic [4:0]        rs_o,
  input logic [31:0]        rs_di,
  output logic [4:0]        rd_o,
  output logic [31:0]       rd_do,
  output logic              flush_o,
  output logic [31:0]       pc_o
);

logic core_halted_n;
logic core_halted_q;
logic reg_req_n;
logic reg_req_q;
logic done_n;
logic done_q;

// halt the core if one of "halt core" or "access register" is true
assign halt_core_o = core_halted_q | reg_req_q;
assign dbg_bus.dut_done = done_q;

always_comb
begin
    core_halted_n = core_halted_q;
    rd_o          = 'b0;
    rd_do         = 'b0;
    rs_o          = 'b0;
    done_n        = 1'b0;
    reg_req_n     = 1'b0;
    flush_o       = 1'b0;
    pc_o          = 'b0;

    case(dbg_bus.cmd)
        8'b0: begin end // Reserverd for no command

        8'h01: begin // halt the core
            done_n = 1'b1;
            core_halted_n = 1'b1;
        end

        8'h02: begin // Resume core
            done_n = 1'b1;
            core_halted_n = 1'b0;
        end

        8'h03: begin // Read register
            // halt the core to mux the register file to the debug module
            reg_req_n     = 1'b1;
            rs_o          = dbg_bus.addr[4:0];
            // Once halted, we can read the register file
            if(core_halted_q) begin
                reg_req_n  = 1'b0;
                done_n  = 1'b1;
                dbg_bus.data_dut_dbg = rs_di;
            end
        end

        8'h04: begin // Write register
            // halt the core to mux the register file to he debug module
            reg_req_n     = 1'b1;
            if(core_halted_q) begin
                rd_o    = dbg_bus.addr[4:0];
                rd_do   = dbg_bus.data_dbg_dut;
                reg_req_n = 1'b0;
                done_n  = 1'b1;
            end
        end

        default: begin end
    endcase
end

always_ff @(posedge clk, negedge rstn_i)
begin
    if(!rstn_i) begin
        core_halted_q <= 1'b0;
    end else begin
        core_halted_q <= core_halted_n;
        reg_req_q     <= reg_req_n;
        done_q        <= done_n;
    end
end

endmodule