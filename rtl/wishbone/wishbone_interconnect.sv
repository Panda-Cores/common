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
// Module name: wishbone_interconnect
// 
// Functionality: My try at a wishbone interconnect
//                sm: slave->master signals
//                ms: master->slave signals
//                mi: master->interconnect signals
//                im: interconnect->master signals
//
// Tests: Single master, single slave                           SUCCESS
//        Single master, multi slave                            SUCCESS
//        Multi master, multi slave, non-simultaneous           SUCCESS
//        Multi master, multi slave, simultaneous read          SUCCESS
//        Multi master, multi slave, simultaneous write         SUCCESS
//        Multi master, multi slave, simultaneous read+write    SUCCESS
//
// TODO: A master that has the bus, cannot be interrupted - if the same
//       master has another request in the next cycle, but a higher prio
//       master also has a request in that cycle, the low prio master
//       is not interrupted. 
//       Interrupting should be allowed, only if the bus is locked (mi_lock_i)
//       it should remain with the current master.
//
// ------------------------------------------------------------

module wishbone_interconnect
#(
    parameter TAGSIZE,
    parameter N_SLAVE,
    parameter N_MASTER
)(
/* verilator lint_off UNDRIVEN */
    input logic                                 clk_i,
    input logic                                 rst_i,       // Active high (as per spec)
    
    // Slave addresse
    input logic [N_SLAVE-1:0][31:0]             SSTART_ADDR, // Slave start addresses
    input logic [N_SLAVE-1:0][31:0]             SEND_ADDR,   // Slave end addresses
    
    // FROM MASTER
    // Data & Address
    input logic [N_MASTER-1:0][31:0]            ms_dat_i,  // master->interconnect data
    input logic [N_MASTER-1:0][TAGSIZE-1:0]     ms_tgd_i,  // data in tag 
    input logic [N_MASTER-1:0][31:0]            ms_adr_i,  // master->interconnect address
    input logic [N_MASTER-1:0][TAGSIZE-1:0]     ms_tga_i,  // address tag
    // Sync
    input logic [N_MASTER-1:0]                  ms_cyc_i,  // transaction cycle in progress
    input logic [N_MASTER-1:0][TAGSIZE-1:0]     ms_tgc_i,  // transaction cycle tag
    input logic [N_MASTER-1:0][3:0]             ms_sel_i,  // select where the data on the data bus (8-bit granularity assumed)
    input logic [N_MASTER-1:0]                  ms_stb_i,  // strobe out, valid data transfer. Slave responds with ack, err or retry to assertion
    input logic [N_MASTER-1:0]                  ms_we_i,   // write enable
    input logic [N_MASTER-1:0]                  mi_lock_i, // lock the interconnect

    // TO MASTER
    // Data
    output logic [31:0]                         sm_dat_o,  // interconnect -> master data
    output logic [TAGSIZE-1:0]                  sm_tgd_o,  // data out tag
    // Sync
    output logic                                sm_ack_o,  // slave ack
    output logic                                sm_err_o,  // slave encountered error
    output logic                                sm_rty_o,  // retry request from slave
    // Sync between mutliple masters (is this still in the spec? Somehow yes and no...)
    output logic [N_MASTER-1:0]                 im_gnt_o, // Grant master the bus

    // FROM SLAVE
    // Data
    input logic [N_SLAVE-1:0][31:0]             sm_dat_i,  // Data from slave
    input logic [N_SLAVE-1:0][TAGSIZE-1:0]      sm_tgd_i,  // data tag
    // Sync
    input logic [N_SLAVE-1:0]                   sm_ack_i,  // slave ack
    input logic [N_SLAVE-1:0]                   sm_err_i,  // slave encountered error
    input logic [N_SLAVE-1:0]                   sm_rty_i,  // retry request from slave

    // TO SLAVE
    // Data & Address
    output logic [31:0]                         ms_dat_o, // data to slave
    output logic [TAGSIZE-1:0]                  ms_tgd_o, // data tag
    output logic [31:0]                         ms_adr_o, // addr to slave
    output logic [TAGSIZE-1:0]                  ms_tga_o, // addr tag
    // Sync
    output logic [N_SLAVE-1:0]                  ms_cyc_o, // Transaction cycle in progress
    output logic [TAGSIZE-1:0]                  ms_tgc_o, // cyc tag
    output logic [3:0]                          ms_sel_o, // select where the data on the data bus (8-bit granularity assumed)
    output logic [N_SLAVE-1:0]                  ms_stb_o, // strobe out, valid data transmission
    output logic                                ms_we_o   // write enable
);

logic [N_MASTER-1:0] master_arbiter_n;
logic [N_MASTER-1:0] master_arbiter_q;
logic [N_SLAVE-1:0]  slave_arbiter;
logic [31:0]         ms_adr;
logic                ms_cyc;
logic                ms_stb;

// Master arbiter select block
// sets master_arbiter to one-hot or 0
always_comb
begin
    master_arbiter_n = master_arbiter_q;
    if((master_arbiter_q & ms_cyc_i) == 'b0) begin // The bus is free!
        master_arbiter_n = 'b0;
        // Give the bus to the highest priority (LSB) master
        for(int i = N_MASTER; i >= 0; i = i - 1)
            if(ms_cyc_i[i]) master_arbiter_n = 'b0 | (1 << i);
    end
end

// Master arbiter
always_comb
begin
    im_gnt_o = 'b0;
    ms_dat_o = '0;
    ms_adr   = '0;
    ms_tgd_o = '0;
    ms_tga_o = '0;
    ms_cyc   = '0;
    ms_tgc_o = '0;
    ms_sel_o = '0;
    ms_stb   = '0;
    ms_we_o  = '0;
    for(int i = 0; i < N_MASTER; i = i + 1) begin
        if(master_arbiter_q == (1 << i)) begin
            // Give the master the bus
            im_gnt_o[i] = 1'b1;
            // mux the data from master to slave
            ms_dat_o = ms_dat_i[i];
            ms_adr   = ms_adr_i[i];
            ms_tgd_o = ms_tgd_i[i];
            ms_tga_o = ms_tga_i[i];
            ms_cyc   = ms_cyc_i[i];
            ms_tgc_o = ms_tgc_i[i];
            ms_sel_o = ms_sel_i[i];
            ms_stb   = ms_stb_i[i];
            ms_we_o  =  ms_we_i[i];
        end
    end
end

// Slave arbiter select block
// sets master_arbiter to one-hot or 0
// TODO: Error if no slave is found
always_comb
begin
    ms_adr_o = 'b0;
    slave_arbiter = 'b0;
    for(int i = 0; i < N_SLAVE; i = i + 1) begin
        if((ms_adr >= SSTART_ADDR[i]) && (ms_adr <= SEND_ADDR[i])) begin
            slave_arbiter = 'b0 | (1 << i);
            // Address out is set off by startaddress of the selected slave
            ms_adr_o = ms_adr - SSTART_ADDR[i];
        end
    end
end

// Slave arbiter
always_comb
begin
    sm_ack_o = 'b0;
    sm_dat_o = 'b0;
    sm_tgd_o = 'b0;
    sm_err_o = 'b0;
    sm_rty_o = 'b0;
    ms_cyc_o = 'b0;
    ms_stb_o = 'b0;
    for(int i = 0; i < N_SLAVE; i = i + 1) begin
        if(slave_arbiter == (1 << i)) begin
            // mux the correct slave to master
            sm_ack_o = sm_ack_i[i];
            sm_dat_o = sm_dat_i[i];
            sm_tgd_o = sm_tgd_i[i];
            sm_err_o = sm_err_i[i];
            sm_rty_o = sm_rty_i[i];
            ms_cyc_o[i] = ms_cyc;
            ms_stb_o[i] = ms_stb;
        end
    end
end

always_ff @(posedge clk_i, posedge rst_i)
begin
    if(rst_i) begin
        
    end else begin
        master_arbiter_q <= master_arbiter_n;
    end
end

endmodule