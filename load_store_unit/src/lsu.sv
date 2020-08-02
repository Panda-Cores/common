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
    wb_bus_t.master             wb_bus
);

logic lu_valid;
logic su_valid;

wb_bus_t#(.TAGSIZE(1)) lu_wb_bus;
wb_bus_t#(.TAGSIZE(1)) su_wb_bus;

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
    wb_bus.wb_dat_ms  = 'b0;
    wb_bus.wb_tgd_ms  = 'b0;
    wb_bus.wb_adr  = 'b0;
    wb_bus.wb_tga  = 'b0;
    wb_bus.wb_cyc  = 'b0;
    wb_bus.wb_tgc  = 'b0;
    wb_bus.wb_sel  = 'b0;
    wb_bus.wb_stb  = 'b0;
    wb_bus.wb_we   = 'b0;
    wb_bus.wb_lock = 'b0;

    if(read_i) begin
        wb_bus.wb_dat_ms  = lu_wb_bus.wb_dat_ms;
        wb_bus.wb_tgd_ms  = lu_wb_bus.wb_tgd_ms;
        wb_bus.wb_adr  = lu_wb_bus.wb_adr;
        wb_bus.wb_tga  = lu_wb_bus.wb_tga;
        wb_bus.wb_cyc  = lu_wb_bus.wb_cyc;
        wb_bus.wb_tgc  = lu_wb_bus.wb_tgc;
        wb_bus.wb_sel  = lu_wb_bus.wb_sel;
        wb_bus.wb_stb  = lu_wb_bus.wb_stb;
        wb_bus.wb_we   = lu_wb_bus.wb_we;
        wb_bus.wb_lock = lu_wb_bus.wb_lock;
        lu_wb_bus.wb_dat_sm = wb_bus.wb_dat_sm;
        lu_wb_bus.wb_tgd_sm = wb_bus.wb_tgd_sm;
        lu_wb_bus.wb_ack = wb_bus.wb_ack;
        lu_wb_bus.wb_err = wb_bus.wb_err;
        lu_wb_bus.wb_rty = wb_bus.wb_rty;
        lu_wb_bus.wb_gnt = wb_bus.wb_gnt;
    end

    if(write_i) begin
        wb_bus.wb_dat_ms  = su_wb_bus.wb_dat_ms;
        wb_bus.wb_tgd_ms  = su_wb_bus.wb_tgd_ms;
        wb_bus.wb_adr  = su_wb_bus.wb_adr;
        wb_bus.wb_tga  = su_wb_bus.wb_tga;
        wb_bus.wb_cyc  = su_wb_bus.wb_cyc;
        wb_bus.wb_tgc  = su_wb_bus.wb_tgc;
        wb_bus.wb_sel  = su_wb_bus.wb_sel;
        wb_bus.wb_stb  = su_wb_bus.wb_stb;
        wb_bus.wb_we   = su_wb_bus.wb_we;
        wb_bus.wb_lock = su_wb_bus.wb_lock;
        su_wb_bus.wb_dat_sm = wb_bus.wb_dat_sm;
        su_wb_bus.wb_tgd_sm = wb_bus.wb_tgd_sm;
        su_wb_bus.wb_ack = wb_bus.wb_ack;
        su_wb_bus.wb_err = wb_bus.wb_err;
        su_wb_bus.wb_rty = wb_bus.wb_rty;
        su_wb_bus.wb_gnt = wb_bus.wb_gnt;
    end
end
    
endmodule