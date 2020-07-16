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
//                The connected slave needs to be able to
//                perform read&write requests instantanious
//
// ------------------------------------------------------------

module wishbone_master #(
    parameter TAGSIZE = 2
)(
    input logic                     clk_i,
    input logic                     rst_i,
    input logic [31:0]              data_i,
    output logic [31:0]             data_o,
    output logic [31:0]             addr_o,
    output logic [31:0]             we_o,
    input logic                     valid_i,
    // Wishbone specifics
    // Data
    input logic [31:0]              wb_dat_i,  // data in
    input logic [TAGSIZE-1:0]       wb_tgd_i,  // data in tag 
    output logic [31:0]             wb_dat_o,  // data out
    output logic [TAGSIZE-1:0]      wb_tgd_o,  // data out tag
    // Address
    input logic                     wb_adr_i,  // address out
    input logic [TAGSIZE-1:0]       wb_tga_i,  // address tag
    // Sync
    output logic                    wb_ack_o,  // acknowledge to master
    input logic                     wb_cyc_i,  // transaction cycle in progress
    input logic [TAGSIZE-1:0]       wb_tgc_i,  // transaction cycle tag
    output logic                    wb_err_o,  // slave encountered error
    output logic                    wb_rty_o,  // retry request from slave
    input logic [3:0]               wb_sel_i,  // select where the data on the data bus (8-bit granularity assumed)
    input logic                     wb_stb_i,  // strobe out, valid data transfer. Slave responds with ack, err or retry to assertion
    input logic                     wb_we_i   // write enable
);

always_comb
begin
    wb_ack_o = 1'b0;
    // Answer to requests, but only if slave is ready
    if(valid_i && (wb_cyc_i || wb_stb_i)) begin
        wb_ack_o = 1'b1;
        addr_o   = wb_adr_i;
        data_o   = wb_dat_i;
        wb_dat_o = data_i;
        we_o     = wb_we_i;
    end
end

endmodule