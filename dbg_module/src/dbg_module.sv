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
//            h00 : Reserved for doing nothing
//            h01 : Read from address
//            h02 : write to address
//            h03 : halt the core
//            h04 : resume the core
//            h05 : reset the core
//            h06 : reset peripherals
//            h07 : reset core & peripherals
//
//
// TODO:      Read & write register file
//            Read (and maybe write for IF) inter-stage pc & instr
//
// ------------------------------------------------------------

module dbg_module #(
  parameter INTERNAL_MEM_S = 32
)(
  input logic               clk,
  input logic               rstn_i,
  input logic [7:0]         cmd_i,
  input logic [31:0]        addr_i,
  input logic [31:0]        data_i,
  output logic [31:0]       data_o,
  output logic              ready_o,
  output logic              core_rst_req_o,
  output logic              periph_rst_req_o,
  dbg_intf.dbg              dbg_intf,
  wb_master_bus_t           wb_bus
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
  dbg_intf.cmd          = 'b0;
  dbg_intf.addr         = 'b0;
  dbg_intf.data_dbg_dut = 'b0;

  case(cmd_i[7:0])
    8'h00: begin // reserved for doing nothing
      ready_n = 1'b1;
    end

    8'h01: begin // Read from addres
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

    8'h03: begin // Halt the core
      ready_n = 1'b0;
      if(dbg_intf.dut_ready) begin
        dbg_intf.cmd = 8'h01;
        if(dbg_intf.dut_done) begin
          dbg_intf.cmd = 8'h0;
          ready_n = 1'b1;
        end
      end
    end

    8'h04: begin // Resume the core
      ready_n = 1'b0;
      if(dbg_intf.dut_ready) begin
        dbg_intf.cmd = 8'h02;
        if(dbg_intf.dut_done) begin
          dbg_intf.cmd = 8'h0;
          ready_n = 1'b1;
        end
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

    8'h10: begin // Read register
      ready_n = 1'b0;
      if(dbg_intf.dut_ready) begin
        dbg_intf.cmd = 8'h02;
        dbg_intf.addr[4:0] = addr_i[4:0];
        if(dbg_intf.dut_done) begin
          dbg_intf.cmd = 8'h0;
          data_n = dbg_intf.data_dut_dbg;
          ready_n = 1'b1;
        end
      end
    end

    8'h20: begin // Write register
      ready_n = 1'b0;
      if(dbg_intf.dut_ready) begin
        dbg_intf.cmd = 8'h02;
        dbg_intf.addr[4:0] = addr_i[4:0];
        dbg_intf.data_dbg_dut = data_i;
        if(dbg_intf.dut_done) begin
          dbg_intf.cmd = 8'h0;
          ready_n = 1'b1;
        end
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