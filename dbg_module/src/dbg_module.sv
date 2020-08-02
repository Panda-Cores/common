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
// Module name: dbg_module
//
// Authors: Luca Hanel
// 
// Functionality: Debug module (not consistent with RISC-V spec!)
//                to make it simpler to run tests & evaluate them.
//                So far, it can halt&resume the core, as well as
//                Reading and writing to memory
//                Also, it can reset core/peripherals/both
//
//                To interact with the debug module, wait for it 
//                to assert 'ready_o' and send a command (listed
//                below). The module will deassert 'ready_o'.
//                All signals need to be stable while the command
//                is being processed. Once it is done, 'ready_o'
//                is again asserted.
//
// Commands:
//          Performed by this module:
//            0x00 : Reserved for doing nothing
//            0x01 : Read from address
//            0x02 : write to address
//            0x03 : reset the core
//            0x04 : reset peripherals
//            0x05 : reset core & peripherals
//          Performed by core-dbg-module:
//            0x11 : halt the core
//            0x12 : resume the core
//            0x13 : read register (address field used)
//            0x14 : write register (address field used)
//            0x15 : read IF-stage PC
//            0x16 : set IF-stage PC and flush the pipeline//
//
// TODO:
//
// ------------------------------------------------------------
/* verilator lint_off MODDUP */
`include "dbg_intf.sv"

module dbg_module(
  input logic               clk,
  input logic               rstn_i,
  input logic [7:0]         cmd_i,
  input logic [31:0]        addr_i,
  input logic [31:0]        data_i,
  output logic [31:0]       data_o,
  output logic              ready_o,
  output logic              core_rst_req_o,
  output logic              periph_rst_req_o,
  dbg_intf.dbg              dbg_bus,
  wb_bus_t.master           wb_bus
);

// Registers
logic [31:0]  data_n, data_q;
logic         ready_n, ready_q;

// LSU signals
logic [31:0]  lsu_data_i, lsu_data_o;
logic [3:0]   lsu_we;
logic   lsu_read;
logic   lsu_write;
logic   lsu_valid;

lsu lsu_i(
    .clk        ( clk       ),
    .rstn_i     ( rstn_i    ),
    .read_i     ( lsu_read  ),
    .write_i    ( lsu_write ),
    .we_i       ( lsu_we    ),
    .addr_i     ( addr_i    ),
    .data_i     ( lsu_data_i),
    .data_o     ( lsu_data_o),
    .valid_o    ( lsu_valid ),
    .wb_bus     ( wb_bus    )
);

assign lsu_data_i = data_i;
assign ready_o  = ready_q;
assign data_o   = data_q;

always_comb
begin
  lsu_read  = 1'b0;
  lsu_write = 1'b0;
  lsu_we    = 4'b0;
  core_rst_req_o = 1'b0;
  periph_rst_req_o = 1'b0;
  ready_n   = ready_q;
  data_n    = data_q;
  dbg_bus.cmd          = 'b0;
  dbg_bus.addr         = 'b0;
  dbg_bus.data_dbg_dut = 'b0;

  case(cmd_i)
    8'h00: begin // reserved for doing nothing
      ready_n = 1'b1;
    end

// Performed by this dbg module
    8'h01: begin // Read from address
      lsu_read  = 1'b1;
      ready_n   = 1'b0;
      if(lsu_valid) begin
        data_n  = lsu_data_o;
        ready_n = 1'b1;
      end
    end

    8'h02: begin // Write to address
      lsu_write = 1'b1;
      lsu_we    = 4'b1111;
      ready_n   = 1'b0;
      if(lsu_valid) begin
        ready_n = 1'b1;
      end
    end

    8'h05: begin // Reset the core
      ready_n = 1'b1;
      core_rst_req_o = 1'b1;
    end

    8'h06: begin // Reset the peripherals
      ready_n = 1'b1;
      periph_rst_req_o = 1'b1;
    end

    8'h07: begin // Reset everything
      ready_n = 1'b1;
      periph_rst_req_o = 1'b1;
      core_rst_req_o = 1'b1;
    end

// performed by core dbg module
    8'h11: begin // Halt the core
      ready_n = 1'b0;
      dbg_bus.cmd = 8'h01;
      if(dbg_bus.dut_done) begin
        dbg_bus.cmd = 8'h0;
        ready_n = 1'b1;
      end
    end

    8'h12: begin // Resume the core
      ready_n = 1'b0;
      dbg_bus.cmd = 8'h02;
      if(dbg_bus.dut_done) begin
        dbg_bus.cmd = 8'h0;
        ready_n = 1'b1;
      end
    end

    8'h13: begin // Read register
      ready_n = 1'b0;
      dbg_bus.cmd = 8'h03;
      dbg_bus.addr[4:0] = addr_i[4:0];
      if(dbg_bus.dut_done) begin
        dbg_bus.cmd = 8'h0;
        data_n = dbg_bus.data_dut_dbg;
        ready_n = 1'b1;
      end
    end

    8'h14: begin // Write register
      ready_n = 1'b0;
      dbg_bus.cmd = 8'h04;
      dbg_bus.addr[4:0] = addr_i[4:0];
      dbg_bus.data_dbg_dut = data_i;
      if(dbg_bus.dut_done) begin
        dbg_bus.cmd = 8'h0;
        ready_n = 1'b1;
      end
    end


    8'h15: begin // Read PC
      ready_n = 1'b0;
      dbg_bus.cmd = 8'h05;
      if(dbg_bus.dut_done) begin
        dbg_bus.cmd = 8'h0;
        data_n = dbg_bus.data_dut_dbg;
        ready_n = 1'b1;
      end
    end

    8'h16: begin // Write PC
      ready_n = 1'b0;
      dbg_bus.cmd = 8'h06;
      dbg_bus.data_dbg_dut = data_i;
      if(dbg_bus.dut_done) begin
        dbg_bus.cmd = 8'h0;
        ready_n = 1'b1;
      end
    end

    default: begin
      ready_n = 1'b1;
    end
  endcase
end

always_ff @(posedge clk, negedge rstn_i)
begin
  if(!rstn_i) begin
    ready_q   <= 1'b1;
    data_q    <= 'b0;
  end else begin
    ready_q   <= ready_n;
    data_q    <= data_n;
  end
end

endmodule