// ------------------------ Disclaimer -----------------------
// No warranty of correctness, synthesizability or 
// functionality of this code is given.
// Use this code under your own risk.
// When using this code, copy this disclaimer at the top of 
// Your file
//
// (c) Luca Hanel 2020
//
// ------------------------------------------------------------
//
// Module name: wishbone_master
// 
// Functionality: My try at a wishbone slave with a simple
//                interface. Does support burst read & write
//
//                As of now, the connected slave needs to be able to
//                perform read&write requests instantanious
//
// ------------------------------------------------------------

module wishbone_slave #(
    parameter TAGSIZE = 2
)(
/* verilator lint_off UNDRIVEN */
    input logic                     clk_i,
    input logic                     rst_i,    // active high, as per spec
    // Slave connections
    input logic [31:0]              data_i,   // data from slave
    output logic [31:0]             data_o,   // data to slave
    output logic [31:0]             addr_o,   // addr to slave
    output logic                    we_o,     // write enable to slave
    output logic [3:0]              sel_o,    // where the data lies, to slave
    input logic                     valid_i,  // slave ack (for later usage, may be extended such that slave can take multiple cycles to respond)
    wb_slave_bus_t                  wb_bus
);

logic [31:0]        wb_dat_i;  // data in
logic [TAGSIZE-1:0] wb_tgd_i;  // data in tag 
logic [31:0]        wb_dat_o;  // data out
logic [TAGSIZE-1:0] wb_tgd_o;  // data out tag
logic [31:0]        wb_adr_i;  // address out
logic [TAGSIZE-1:0] wb_tga_i;  // address tag
logic               wb_ack_o;  // acknowledge to master
logic               wb_cyc_i;  // transaction cycle in progress
logic [TAGSIZE-1:0] wb_tgc_i;  // transaction cycle tag
logic               wb_err_o;  // slave encountered error
logic               wb_rty_o;  // retry request from slave
logic [3:0]         wb_sel_i;  // select where the data on the data bus (8-bit granularity assumed)
logic               wb_stb_i;  // strobe out, valid data transfer. Slave responds with ack, err or retry to assertion
logic               wb_we_i;   // write enable

// local variables to wishbone bus (just dont want to rewrite everything ':D)
assign wb_dat_i = wb_bus.wb_dat_i;
assign wb_tgd_i = wb_bus.wb_tgd_i;
assign wb_adr_i = wb_bus.wb_adr_i;
assign wb_tga_i = wb_bus.wb_tga_i;
assign wb_cyc_i = wb_bus.wb_cyc_i;
assign wb_tgc_i = wb_bus.wb_tgc_i;
assign wb_sel_i = wb_bus.wb_sel_i;
assign wb_stb_i = wb_bus.wb_stb_i;
assign wb_we_i  = wb_bus.wb_we_i;
assign wb_bus.wb_dat_o = wb_dat_o;
assign wb_bus.wb_tgd_o = wb_tgd_o;
assign wb_bus.wb_ack_o = wb_ack_o;
assign wb_bus.wb_err_o = wb_err_o;
assign wb_bus.wb_rty_o = wb_rty_o;

always_comb
begin
    wb_ack_o = 1'b0;
    // Answer to requests, but only if slave is ready
    if(valid_i && (wb_cyc_i && wb_stb_i)) begin
        wb_ack_o = 1'b1;
        addr_o   = wb_adr_i;
        data_o   = wb_dat_i;
        wb_dat_o = data_i;
        we_o     = wb_we_i;
        sel_o    = wb_sel_i;
    end
end

endmodule