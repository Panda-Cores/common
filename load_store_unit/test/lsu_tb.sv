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
// Module name: lsu_tb
//
// Authors: Luca Hanel
// 
// Functionality: testbench for the lsu
//
// TODO: 
//
// ------------------------------------------------------------

module lsu_tb(
    input logic             clk,
    input logic             rstn_i,
    input logic             read_i,
    input logic             write_i,
    input logic [31:0]      addr_i,
    input logic [31:0]      data_i,
    output logic [31:0]     data_o,
    output logic            valid_o
);

wb_master_bus_t#(.TAGSIZE(1)) wb_lsu_bus[1];
wb_slave_bus_t#(.TAGSIZE(1)) wb_ram_bus[1];

wishbone_interconnect #(
    .TAGSIZE    (1),
    .N_SLAVE    ( 1 ),
    .N_MASTER   ( 1 )
) intercon (
    .clk_i      ( clk ),
    .rst_i      ( ~rstn_i ),
    .SSTART_ADDR({32'h0}),
    .SEND_ADDR  ({32'h80}),
    .wb_master_bus(wb_lsu_bus),
    .wb_slave_bus(wb_ram_bus)
);


lsu lsu_i(
    .clk        ( clk       ),
    .rstn_i     ( rstn_i    ),
    .read_i     ( read_i    ),
    .write_i    ( write_i   ),
    .addr_i     ( addr_i    ),
    .data_i     ( data_i    ),
    .data_o     ( data_o    ),
    .valid_o    ( valid_o   ),
    .wb_bus     ( wb_lsu_bus[0])
);

wb_ram_wrapper #(
    .SIZE ( 32  )
)ram_i(
    .clk        ( clk       ),
    .rstn_i     ( rstn_i    ),
    .wb_bus     ( wb_ram_bus[0])
);

endmodule