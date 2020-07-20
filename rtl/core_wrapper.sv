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
// Module name: core_wrapper
// 
// Functionality: wrapper for the core to hide the ugliness
//
// ------------------------------------------------------------

module core_wrapper
(
    input wire          clk,
    input wire          rstn_i,
    input wire          halt_core_i,
    output wire         rst_o
);

logic rst_reqn;

assign rst_o = ~rst_reqn;

wb_master_bus_t wb_masters[2];
wb_slave_bus_t wb_slaves[1];

core_top core_i
(
    .clk        ( clk          ),
    .rstn_i     ( rstn_i       ),
    .halt_core_i( halt_core_i  ),
    .rst_reqn_o ( rst_reqn     ),
    .wb_masters ( wb_masters   )
);

wishbone_interconnect #(
  .N_SLAVE        ( 1 ),
  .N_MASTER       ( 2 )
) wb_interconnect (
  .clk_i          ( clk         ),
  .rst_i          ( ~rstn_i     ),
  .SSTART_ADDR    ( {32'h0}     ),
  .SEND_ADDR      ( {32'h1f}    ),
  .wb_master_bus  ( wb_masters  ),
  .wb_slave_bus   ( wb_slaves   )
);

wb_ram_wrapper #(
  .SIZE (32 )
) ram_i (
  .clk      ( clk       ),
  .rstn_i   ( rstn_i    ),
  .wb_bus   ( wb_slaves[0] )
);

endmodule