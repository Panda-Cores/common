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
// Module name: wishbone_tb
// 
// Functionality: wishbone testbench
//
// ------------------------------------------------------------

module wishbone_tb
(
    input logic         clk,
    input logic         rstn_i,
    input logic [31:0]  m0data_i,
    output logic [31:0] m0data_o,
    input logic [31:0]  m0addr_i,
    input logic [3:0]   m0we_i,
    input logic         m0valid_i,
    output logic        m0valid_o
);
/* verilator lint_off PINMISSING */

parameter N_MASTER = 1;
parameter N_SLAVE = 1;

logic [31:0] m0dat_i;
logic [31:0] m0dat_o;
logic [31:0] m0adr_o;
logic        m0ack_i;
logic        m0cyc_o;
logic        m0stb_o;
logic        m0we_o;
logic [3:0]  m0sel_i;

logic [31:0] s0dat_o;
logic [31:0] s0dat_i;
logic [31:0] s0adr_i;

logic [3:0]             mi_sel;
logic                   mi_stb;
logic                   mi_cyc;
logic                   mi_we;
logic [31:0]            mi_adr;
logic [31:0]            mi_dat;
logic [31:0]            im_dat;
logic [N_MASTER-1:0]    im_gnt;
logic                   im_ack;
logic [31:0]            is_adr;
logic [31:0]            si_dat;
logic [31:0]            is_dat;

wishbone_interconnect #(
    .TAGSIZE    ( 0 ),
    .N_SLAVE    ( 1 ),
    .N_MASTER   ( 1 ),
    .SSTART_ADDR ( 'b0 ),
    .SEND_ADDR  ( 'h1f)
) intercon (
    .clk_i      ( clk ),
    .rst_i      ( ~rstn_i ),
    // From master
    .ms_dat_i   ( mi_dat    ),
    .ms_adr_i   ( mi_adr    ),
    .ms_cyc_i   ( mi_cyc    ),
    .ms_sel_i   ( mi_sel    ),
    .ms_stb_i   ( mi_stb    ),
    .ms_we_i    ( mi_we     ),
    // To master
    .sm_dat_o   ( im_dat    ),
    .sm_ack_o   ( im_ack    ),
    .im_gnt_o   ( im_gnt    ),
    // From slave
    .sm_dat_i   ( si_dat    ),
    .sm_ack_i   ( si_ack    ),
    // To salve
    .ms_dat_o   ( is_dat    ),
    .ms_adr_o   ( is_adr    ),
    .ms_cyc_o   ( is_cyc    ),
    .ms_sel_o   ( is_sel    ),
    .ms_stb_o   ( is_stb    ),
    .ms_we_o    ( is_we     )
);

wishbone_master #(
    .TAGSIZE    ( 0 )
) wbmaster0 (
    .clk_i      ( clk       ),
    .rst_i      ( ~rstn_i   ),
    .data_i     ( m0data_i  ),
    .data_o     ( m0data_o  ),
    .addr_i     ( m0addr_i  ),
    .we_i       ( m0we_i    ),
    .valid_i    ( m0valid_i ),
    .valid_o    ( m0valid_o ),
    .wb_dat_i   ( im_dat    ),
    .wb_dat_o   ( m0dat_o   ),
    .wb_adr_o   ( m0adr_o   ),
    .wb_ack_i   ( im_ack    ),
    .wb_cyc_o   ( m0cyc_o   ),
    .wb_sel_o   ( m0sel_o   ),
    .wb_stb_o   ( m0stb_o   ),
    .wb_we_o    ( m0we_o    ),
    .wb_gnt_i   ( im_gnt[0] )
);

wishbone_slave #(
    .TAGSIZE    ( 0 )
) wbslave0 (
    .clk_i      ( clk      ),
    .rst_i      ( ~rstn_i  ),
    .data_i     ( s0data_i ),
    .data_o     ( s0data_o ),
    .addr_o     ( s0addr   ),
    .we_o       ( s0we     ),
    .sel_o      ( s0sel    ),
    .valid_i    ( 1'b1     ),
    .wb_dat_o   ( s0dat_o  ),
    .wb_dat_i   ( s0dat_i  ),
    .wb_adr_i   ( s0adr_i  ),
    .wb_ack_o   ( s0ack_o  ),
    .wb_cyc_i   ( s0cyc_i  ),
    .wb_sel_i   ( s0sel_i  ),
    .wb_stb_i   ( s0stb_i  ),
    .wb_we_i    ( s0we_i   )
);

assign s0wes = (s0we) ? s0sel : 'b0;

dual_ram #(
    .SIZE ( 32 )
) slave0 (
    .clk        ( clk       ),
    .rstn_i     ( rstn_i    ),
    .addrb_i    ( s0addr    ),
    .enb_i      ( 1'b1      ),
    .web_i      ( s0wes     ),
    .dinb_i     ( s0data_o  ),
    .doutb_o    ( s0data_i  )
);

endmodule