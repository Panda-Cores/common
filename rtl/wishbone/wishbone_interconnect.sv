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
// TODO: everything
//
// ------------------------------------------------------------

module wishbone_interconnect
#(
    parameter TAGSIZE,
    parameter N_SLAVE,
    parameter N_MASTER,
    parameter SSTART_ADDR[N_SLAVE],
    parameter SEND_ADDR[N_SLAVE]
)(
    input logic                     clk_i,
    input logic                     rst_i,
    // FROM MASTER
    // Data & Address
    input logic [31:0]              ms_dat_i[N_MASTER],  // master->interconnect data
    input logic [TAGSIZE-1:0]       ms_tgd_i[N_MASTER],  // data in tag 
    input logic                     ms_adr_i[N_MASTER],  // master->interconnect address
    input logic [TAGSIZE-1:0]       ms_tga_i[N_MASTER],  // address tag
    // Sync
    input logic                     ms_ack_i[N_MASTER],  // acknowledge from master
    input logic                     ms_cyc_i[N_MASTER],  // transaction cycle in progress
    input logic [TAGSIZE-1:0]       ms_tgc_i[N_MASTER],  // transaction cycle tag
    input logic [3:0]               ms_sel_i[N_MASTER],  // select where the data on the data bus (8-bit granularity assumed)
    input logic                     ms_stb_i[N_MASTER],  // strobe out, valid data transfer. Slave responds with ack, err or retry to assertion
    input logic                     ms_we_i[N_MASTER],   // write enable
    input logic                     mi_lock_i[N_MASTER], // lock the interconnect

    // TO MASTER
    // Data
    output logic [31:0]             sm_dat_o,  // interconnect -> master data
    output logic [TAGSIZE-1:0]      sm_tgd_o,  // data out tag
    // Sync
    output logic                    sm_ack_o,  // slave ack
    output logic                    sm_err_o,  // slave encountered error
    output logic                    sm_rty_o,  // retry request from slave
    // Sync between mutliple masters (is this still in the spec? Somehow yes and no...)
    output logic                    im_gnt_o[N_MASTER], // Grant master the bus

    // FROM SLAVE
    // Data
    input logic [31:0]              sm_dat_i[N_SLAVE],  // Data from slave
    input logic [TAGSIZE-1:0]       sm_tgd_i[N_SLAVE],  // data tag
    // Sync
    input logic                     sm_ack_i[N_SLAVE],  // slave ack
    input logic                     sm_err_i[N_SLAVE],  // slave encountered error
    input logic                     sm_rty_i[N_SLAVE],  // retry request from slave

    // TO SLAVE
    // Data & Address
    output logic [31:0]             ms_dat_o, // data to slave
    output logic [TAGSIZE-1:0]      ms_tgd_o, // data tag
    output logic [31:0]             ms_adr_o, // addr to slave
    output logic [TAGSIZE-1:0]      ms_tga_o, // addr tag
    // Sync
    output logic                    ms_cyc_o, // Transaction cycle in progress
    output logic [TAGSIZE-1:0]      ms_tgc_o, // cyc tag
    output logic                    ms_ack_o, // master ack
    output logic [3:0]              ms_sel_o, // select where the data on the data bus (8-bit granularity assumed)
    output logic                    ms_stb_o, // strobe out, valid data transmission
    output logic                    ms_we_o   // write enable
);

logic [N_MASTER-1:0] master_arbiter_n;
logic [N_MASTER-1:0] master_arbiter_q;
logic [N_SLAVE-1:0]  slave_arbiter;

// Master arbiter select block
// sets master_arbiter to one-hot or 0
always_comb
begin
    master_arbiter_n = master_arbiter_q;
    if((master_arbiter_q & ms_cyc_i) == 'b0) begin // The bus is free!
        master_arbiter_n = 'b0;
        // Give the bus to the highest priority (LSB) master
        for(int i = N_MASTER; i >= 0; i = i - 1)
            if(ms_cyc_i[i]) master_arbiter_n = 'b0 & (1 << i);
    end
end

// Master arbiter
always_comb
begin
    im_gnt_o = 'b0;
    ms_dat_o = '0;
    ms_adr_o = '0;
    ms_tgd_o = '0;
    ms_tga_o = '0;
    ms_ack_o = '0;
    ms_cyc_o = '0;
    ms_tgc_o = '0;
    ms_sel_o = '0;
    ms_stb_o = '0;
    ms_we_o  = '0;
    for(int i = 0; i < N_MASTER; i = i + 1) begin
        if(master_arbiter_q == (1 << i)) begin
            // Give the master the bus
            im_gnt_o[i] = 1'b1;
            // mux the data from master to slave
            ms_dat_o = ms_dat_i[masters];
            ms_adr_o = ms_adr_i[masters];
            ms_tgd_o = ms_tgd_i[masters];
            ms_tga_o = ms_tga_i[masters];
            ms_ack_o = ms_ack_i[masters];
            ms_cyc_o = ms_cyc_i[masters];
            ms_tgc_o = ms_tgc_i[masters];
            ms_sel_o = ms_sel_i[masters];
            ms_stb_o = ms_stb_i[masters];
            ms_we_o  = ms_we_i[masters];
        end
    end
end

// Slave arbiter select block
// sets master_arbiter to one-hot or 0
// TODO: Error if no slave is found
always_comb
begin
    slave_arbiter = 'b0;
    for(int i = 0; i < N_SLAVE; i = i + 1) begin
        if(ms_adr_o > SSTART_ADDR[i] && ms_adr_o < SEND_ADDR)
            slave_arbiter = 'b0 & (1 << i);
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
    for(int i = 0; i < N_SLAVE; i = i + 1) begin
        if(slave_arbiter == (1 << i)) begin
            // mux the correct slave to master
            sm_ack_o = sm_ack_i[i];
            sm_dat_o = sm_dat_i[i];
            sm_tgd_o = sm_tgd_i[i];
            sm_err_o = sm_err_i[i];
            sm_rty_o = sm_rty_i[i];
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