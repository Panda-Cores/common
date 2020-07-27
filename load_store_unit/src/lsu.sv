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
// Module name: lsu
//
// Authors: Luca Hanel
// 
// Functionality: Load-Store-Unit, handles both loads and stores
//
// TODO: 
//
// ------------------------------------------------------------

module lsu(
    input logic                 clk,
    input logic                 rstn_i,
    input logic                 read_i,
    input logic                 write_i,
    input logic [3:0]           we_i,
    input logic [31:0]          addr_i,
    input logic [31:0]          data_i,
    output logic [31:0]         data_o,
    output logic                valid_o,
    wb_master_bus_t             wb_bus
);

logic lu_valid;
logic su_valid;

wb_master_bus_t#(.TAGSIZE(1)) lu_wb_bus;
wb_master_bus_t#(.TAGSIZE(1)) su_wb_bus;

assert property (@(edge clk) !(write_i && read_i))
    else $error("reading and writing at the same time!");

assign valid_o = (lu_valid & read_i) | (su_valid & write_i);

load_unit lu_i(
    .clk            ( clk       ),
    .rstn_i         ( rstn_i    ),
    .read_i         ( read_i    ),
    .addr_i         ( addr_i    ),
    .valid_o        ( lu_valid  ),
    .data_o         ( data_o    ),
    .wb_bus         ( lu_wb_bus )
);

store_unit su_i(
    .clk            ( clk       ),
    .rstn_i         ( rstn_i    ),
    .write_i        ( write_i   ),
    .we_i           ( we_i      ),
    .addr_i         ( addr_i    ),
    .data_i         ( data_i    ),
    .valid_o        ( su_valid  ),
    .wb_bus         ( su_wb_bus )
);

always_comb
begin
    wb_bus.wb_dat_o  = 'b0;
    wb_bus.wb_tgd_o  = 'b0;
    wb_bus.wb_adr_o  = 'b0;
    wb_bus.wb_tga_o  = 'b0;
    wb_bus.wb_cyc_o  = 'b0;
    wb_bus.wb_tgc_o  = 'b0;
    wb_bus.wb_sel_o  = 'b0;
    wb_bus.wb_stb_o  = 'b0;
    wb_bus.wb_we_o   = 'b0;
    wb_bus.wb_lock_o = 'b0;

    if(read_i) begin
        wb_bus.wb_dat_o  = lu_wb_bus.wb_dat_o;
        wb_bus.wb_tgd_o  = lu_wb_bus.wb_tgd_o;
        wb_bus.wb_adr_o  = lu_wb_bus.wb_adr_o;
        wb_bus.wb_tga_o  = lu_wb_bus.wb_tga_o;
        wb_bus.wb_cyc_o  = lu_wb_bus.wb_cyc_o;
        wb_bus.wb_tgc_o  = lu_wb_bus.wb_tgc_o;
        wb_bus.wb_sel_o  = lu_wb_bus.wb_sel_o;
        wb_bus.wb_stb_o  = lu_wb_bus.wb_stb_o;
        wb_bus.wb_we_o   = lu_wb_bus.wb_we_o;
        wb_bus.wb_lock_o = lu_wb_bus.wb_lock_o;
        lu_wb_bus.wb_dat_i = wb_bus.wb_dat_i;
        lu_wb_bus.wb_tgd_i = wb_bus.wb_tgd_i;
        lu_wb_bus.wb_ack_i = wb_bus.wb_ack_i;
        lu_wb_bus.wb_err_i = wb_bus.wb_err_i;
        lu_wb_bus.wb_rty_i = wb_bus.wb_rty_i;
        lu_wb_bus.wb_gnt_i = wb_bus.wb_gnt_i;
    end

    if(write_i) begin
        wb_bus.wb_dat_o  = su_wb_bus.wb_dat_o;
        wb_bus.wb_tgd_o  = su_wb_bus.wb_tgd_o;
        wb_bus.wb_adr_o  = su_wb_bus.wb_adr_o;
        wb_bus.wb_tga_o  = su_wb_bus.wb_tga_o;
        wb_bus.wb_cyc_o  = su_wb_bus.wb_cyc_o;
        wb_bus.wb_tgc_o  = su_wb_bus.wb_tgc_o;
        wb_bus.wb_sel_o  = su_wb_bus.wb_sel_o;
        wb_bus.wb_stb_o  = su_wb_bus.wb_stb_o;
        wb_bus.wb_we_o   = su_wb_bus.wb_we_o;
        wb_bus.wb_lock_o = su_wb_bus.wb_lock_o;
        su_wb_bus.wb_dat_i = wb_bus.wb_dat_i;
        su_wb_bus.wb_tgd_i = wb_bus.wb_tgd_i;
        su_wb_bus.wb_ack_i = wb_bus.wb_ack_i;
        su_wb_bus.wb_err_i = wb_bus.wb_err_i;
        su_wb_bus.wb_rty_i = wb_bus.wb_rty_i;
        su_wb_bus.wb_gnt_i = wb_bus.wb_gnt_i;
    end
end
    
endmodule