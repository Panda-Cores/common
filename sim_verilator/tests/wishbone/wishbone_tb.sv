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
    input logic [1:0][31:0]  mdata_i,
    output logic [1:0][31:0] mdata_o,
    input logic [1:0][31:0]  maddr_i,
    input logic [1:0][3:0]   mwe_i,
    input logic [1:0]        mvalid_i,
    output logic [1:0]       mvalid_o
);
/* verilator lint_off PINMISSING */
/* verilator lint_off UNDRIVEN */

parameter N_MASTER = 2;
parameter N_SLAVE = 2;

//master0
logic [31:0] m0dat_i;
logic [31:0] m0dat_o;
logic [31:0] m0adr_o;
logic        m0ack_i;
logic        m0cyc_o;
logic        m0stb_o;
logic        m0we_o;
logic [3:0]  m0sel_o;

//master1
logic [31:0] m1dat_i;
logic [31:0] m1dat_o;
logic [31:0] m1adr_o;
logic        m1ack_i;
logic        m1cyc_o;
logic        m1stb_o;
logic        m1we_o;
logic [3:0]  m1sel_o;

//slave0
logic [31:0] s0dat_o;
logic [31:0] s0dat_i;
logic [31:0] s0adr_i;
logic        s0ack_o;

//slave1
logic [31:0] s1dat_o;
logic [31:0] s1dat_i;
logic [31:0] s1adr_i;
logic        s1ack_o;

logic [N_MASTER-1:0][3:0]             mi_sel;
logic [N_MASTER-1:0]                  mi_stb;
logic [N_MASTER-1:0]                  mi_cyc;
logic [N_MASTER-1:0]                  mi_we;
logic [N_MASTER-1:0][31:0]            mi_adr;
logic [N_MASTER-1:0][31:0]            mi_dat;

logic [31:0]            im_dat;
logic [N_MASTER-1:0]    im_gnt;
logic                   im_ack;

logic [31:0]            is_adr;
logic [31:0]            is_dat;
logic [N_SLAVE-1:0]     is_cyc;
logic [3:0]             is_sel;
logic [N_SLAVE-1:0]     is_stb;
logic                   is_we;

logic [N_SLAVE-1:0][31:0]            si_dat;
logic [N_SLAVE-1:0]                  si_ack;

//slave0
logic [31:0] s0data_i;
logic [31:0] s0data_o;
logic [31:0] s0addr_o;
logic        s0cyc_i;
logic        s0stb_i;
logic [3:0]  s0wes;
logic [3:0]  s0sel;
logic        s0we;

//slave1
logic [31:0] s1data_i;
logic [31:0] s1data_o;
logic [31:0] s1addr_o;
logic        s1cyc_i;
logic        s1stb_i;
logic [3:0]  s1wes;
logic [3:0]  s1sel;
logic        s1we;

assign s0wes = (s0we) ? s0sel : 'b0;
assign s1wes = (s1we) ? s1sel : 'b0;

assign mi_dat = {m1dat_o, m0dat_o};
assign mi_adr = {m1adr_o, m0adr_o};
assign mi_cyc = {m1cyc_o, m0cyc_o};
assign mi_sel = {m1sel_o, m0sel_o};
assign mi_stb = {m1stb_o, m0stb_o};
assign mi_we  = {m1we_o, m0we_o};

assign si_dat = {s1dat_o, s0dat_o};
assign si_ack = {s1ack_o, s0ack_o};
assign s0cyc_i = is_cyc[0];
assign s1cyc_i = is_cyc[1];
assign s0stb_i = is_stb[0];
assign s1stb_i = is_stb[1];

wishbone_interconnect #(
    .TAGSIZE    (1),
    .N_SLAVE    ( N_SLAVE ),
    .N_MASTER   ( N_MASTER )
) intercon (
    .clk_i      ( clk ),
    .rst_i      ( ~rstn_i ),
    .SSTART_ADDR({32'h10, 32'h0}),
    .SEND_ADDR  ({32'h1f, 32'hf}),
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
    .TAGSIZE    (1)
) wbmaster0 (
    .clk_i      ( clk       ),
    .rst_i      ( ~rstn_i   ),
    .data_i     ( mdata_i[0]  ),
    .data_o     ( mdata_o[0]  ),
    .addr_i     ( maddr_i[0]  ),
    .we_i       ( mwe_i[0]    ),
    .valid_i    ( mvalid_i[0] ),
    .valid_o    ( mvalid_o[0] ),
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

wishbone_master #(
    .TAGSIZE    (1)
) wbmaster1 (
    .clk_i      ( clk       ),
    .rst_i      ( ~rstn_i   ),
    .data_i     ( mdata_i[1]  ),
    .data_o     ( mdata_o[1]  ),
    .addr_i     ( maddr_i[1]  ),
    .we_i       ( mwe_i[1]    ),
    .valid_i    ( mvalid_i[1] ),
    .valid_o    ( mvalid_o[1] ),
    .wb_dat_i   ( im_dat    ),
    .wb_dat_o   ( m1dat_o   ),
    .wb_adr_o   ( m1adr_o   ),
    .wb_ack_i   ( im_ack    ),
    .wb_cyc_o   ( m1cyc_o   ),
    .wb_sel_o   ( m1sel_o   ),
    .wb_stb_o   ( m1stb_o   ),
    .wb_we_o    ( m1we_o    ),
    .wb_gnt_i   ( im_gnt[1] )
);

wishbone_slave #(
    .TAGSIZE    (1)
) wbslave0 (
    .clk_i      ( clk      ),
    .rst_i      ( ~rstn_i  ),
    .data_i     ( s0data_i ),
    .data_o     ( s0data_o ),
    .addr_o     ( s0addr_o   ),
    .we_o       ( s0we     ),
    .sel_o      ( s0sel    ),
    .valid_i    ( 1'b1     ),
    .wb_dat_o   ( s0dat_o  ),
    .wb_dat_i   ( is_dat   ),
    .wb_adr_i   ( is_adr   ),
    .wb_ack_o   ( s0ack_o  ),
    .wb_cyc_i   ( s0cyc_i  ),
    .wb_sel_i   ( is_sel   ),
    .wb_stb_i   ( s0stb_i   ),
    .wb_we_i    ( is_we    )
);

wishbone_slave #(
    .TAGSIZE    (1)
) wbslave1 (
    .clk_i      ( clk      ),
    .rst_i      ( ~rstn_i  ),
    .data_i     ( s1data_i ),
    .data_o     ( s1data_o ),
    .addr_o     ( s1addr_o   ),
    .we_o       ( s1we     ),
    .sel_o      ( s1sel    ),
    .valid_i    ( 1'b1     ),
    .wb_dat_o   ( s1dat_o  ),
    .wb_dat_i   ( is_dat   ),
    .wb_adr_i   ( is_adr   ),
    .wb_ack_o   ( s1ack_o  ),
    .wb_cyc_i   ( s1cyc_i   ),
    .wb_sel_i   ( is_sel   ),
    .wb_stb_i   ( s1stb_i   ),
    .wb_we_i    ( is_we    )
);

dual_ram #(
    .SIZE ( 32 )
) slave0 (
    .clk        ( clk       ),
    .rstn_i     ( rstn_i    ),
    .addrb_i    ( s0addr_o    ),
    .enb_i      ( 1'b1      ),
    .web_i      ( s0wes     ),
    .dinb_i     ( s0data_o  ),
    .doutb_o    ( s0data_i  )
);

dual_ram #(
    .SIZE ( 32 )
) slave1 (
    .clk        ( clk       ),
    .rstn_i     ( rstn_i    ),
    .addrb_i    ( s1addr_o    ),
    .enb_i      ( 1'b1      ),
    .web_i      ( s1wes     ),
    .dinb_i     ( s1data_o  ),
    .doutb_o    ( s1data_i  )
);

endmodule