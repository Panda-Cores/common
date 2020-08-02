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
// Functionality: A debug module for the core, can read registers,
//                can flush the pipeline and set&read the pc
//
// Commands:
//            0x0:  Reserved for doing nothing
//            0x1:  Halt the core
//            0x2:  Resume the core
//            0x3:  Read from register file
//            0x4:  Write to register file
//            0x5:  Read pc
//            0x6:  Write pc & flush the pipeline
//
// TODO:
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
  input logic [31:0]        pc_i,
  output logic [31:0]       pc_o
);

logic core_halted_n;
logic core_halted_q;
logic tmp_halt_n;
logic tmp_halt_q;
logic done_n;
logic done_q;

// halt the core if one of "halt core" or "access register" is true
assign halt_core_o = core_halted_q | tmp_halt_q;
assign dbg_bus.dut_done = done_q;

always_comb
begin
    core_halted_n = core_halted_q;
    rd_o          = 'b0;
    rd_do         = 'b0;
    rs_o          = 'b0;
    done_n        = 1'b0;
    tmp_halt_n     = 1'b0;
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
            tmp_halt_n     = 1'b1;
            rs_o          = dbg_bus.addr[4:0];
            // Once halted, we can read the register file
            if(tmp_halt_q || core_halted_q) begin
                tmp_halt_n  = 1'b0;
                done_n  = 1'b1;
                dbg_bus.data_dut_dbg = rs_di;
            end
        end

        8'h04: begin // Write register
            // halt the core to mux the register file to he debug module
            tmp_halt_n     = 1'b1;
            if(tmp_halt_q || core_halted_q) begin
                rd_o    = dbg_bus.addr[4:0];
                rd_do   = dbg_bus.data_dbg_dut;
                tmp_halt_n = 1'b0;
                done_n  = 1'b1;
            end
        end

        8'h05: begin // Read the pc
            done_n = 1'b1;
            dbg_bus.data_dut_dbg = pc_i;
        end

        8'h06: begin // Set the pc
            tmp_halt_n  = 1'b1;
            flush_o     = 1'b1;
            pc_o        = dbg_bus.data_dbg_dut;
            if(tmp_halt_q) begin
                done_n    = 1'b1;
                tmp_halt_n = 1'b0;
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
        tmp_halt_q     <= tmp_halt_n;
        done_q        <= done_n;
    end
end

endmodule
