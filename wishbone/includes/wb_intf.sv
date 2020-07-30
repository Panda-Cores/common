/* verilator lint_off DECLFILENAME */
`ifndef WB_BUS_SV
`define WB_BUS_SV
interface wb_bus_t #(parameter TAGSIZE=2);
    logic [31:0]        wb_dat_sm;  // data in
    logic [TAGSIZE-1:0] wb_tgd_sm;  // data in tag 
    logic [31:0]        wb_dat_ms;  // data out
    logic [TAGSIZE-1:0] wb_tgd_ms;  // data out tag
    logic [31:0]        wb_adr;  // address out
    logic [TAGSIZE-1:0] wb_tga;  // address tag
    logic               wb_ack;  // acknowledge from slave
    logic               wb_cyc;  // transaction cycle in progress
    logic [TAGSIZE-1:0] wb_tgc;  // transaction cycle tag
    logic               wb_err;  // slave encountered error
    logic               wb_lock;    // lock the interconnect
    logic               wb_rty;  // retry request from slave
    logic [3:0]         wb_sel;  // select where the data on the data bus (8-bit granularity assumed)
    logic               wb_stb;  // strobe out, valid data transfer. Slave responds with ack, err or retry to assertion
    logic               wb_we;   // write enable
    logic               wb_gnt;     // Bus granted by interconnect

    modport master (
        input wb_dat_sm, wb_tgd_sm, wb_ack, wb_err, wb_rty, wb_gnt,
        output wb_dat_ms, wb_tgd_ms, wb_adr, wb_tga, wb_cyc, wb_tgc, wb_lock, wb_sel, wb_stb, wb_we
    );

    modport slave (
        input wb_dat_ms, wb_tgd_ms, wb_adr, wb_tga, wb_cyc, wb_tgc, wb_lock, wb_sel, wb_stb, wb_we,
        output wb_dat_sm, wb_tgd_sm, wb_ack, wb_err, wb_rty, wb_gnt
    );
endinterface //wb_master_bus
`endif
/* verilator lint_on DECLFILENAME */