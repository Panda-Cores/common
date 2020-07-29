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

`include "wishbone_interfaces.sv"

module wishbone_interconnect
#(
    parameter TAGSIZE = 2,
    parameter N_SLAVE,
    parameter N_MASTER
)(
/* verilator lint_off UNDRIVEN */
    input logic                     clk_i,
    input logic                     rst_i,       // Active high (as per spec)
    
    // Slave addresses
    input logic [N_SLAVE-1:0][31:0] SSTART_ADDR, // Slave start addresses
    input logic [N_SLAVE-1:0][31:0] SEND_ADDR,   // Slave end addresses
    
    // MASTERS
    wb_master_bus_t                 wb_master_bus[N_MASTER],
    // SLAVES
    wb_slave_bus_t                  wb_slave_bus[N_SLAVE]
);

// master signals
logic [N_MASTER-1:0][31:0]        ms_dat_i;  // master->interconnect data
logic [N_MASTER-1:0][TAGSIZE-1:0] ms_tgd_i;  // data in tag 
logic [N_MASTER-1:0][31:0]        ms_adr_i;  // master->interconnect address
logic [N_MASTER-1:0][TAGSIZE-1:0] ms_tga_i;  // address tag
logic [N_MASTER-1:0]              ms_cyc_i;  // transaction cycle in progress
logic [N_MASTER-1:0][TAGSIZE-1:0] ms_tgc_i;  // transaction cycle tag
logic [N_MASTER-1:0][3:0]         ms_sel_i;  // select where the data on the data bus (8-bit granularity assumed)
logic [N_MASTER-1:0]              ms_stb_i;  // strobe out, valid data transfer. Slave responds with ack, err or retry to assertion
logic [N_MASTER-1:0]              ms_we_i;   // write enable
logic [N_MASTER-1:0]              mi_lock_i; // lock the interconnect
logic [31:0]                      sm_dat_o;  // interconnect -> master data
logic [TAGSIZE-1:0]               sm_tgd_o;  // data out tag
logic                             sm_ack_o;  // slave ack
logic                             sm_err_o;  // slave encountered error
logic                             sm_rty_o;  // retry request from slave
logic [N_MASTER-1:0]              im_gnt_o; // Grant master the bus

// slave signals
logic [N_SLAVE-1:0][31:0]        sm_dat_i;  // Data from slave
logic [N_SLAVE-1:0][TAGSIZE-1:0] sm_tgd_i;  // data tag
logic [N_SLAVE-1:0]              sm_ack_i;  // slave ack
logic [N_SLAVE-1:0]              sm_err_i;  // slave encountered error
logic [N_SLAVE-1:0]              sm_rty_i;  // retry request from slave
logic [31:0]                     ms_dat_o; // data to slave
logic [TAGSIZE-1:0]              ms_tgd_o; // data tag
logic [31:0]                     ms_adr_o; // addr to slave
logic [TAGSIZE-1:0]              ms_tga_o; // addr tag
logic [N_SLAVE-1:0]              ms_cyc_o; // Transaction cycle in progress
logic [TAGSIZE-1:0]              ms_tgc_o; // cyc tag
logic [3:0]                      ms_sel_o; // select where the data on the data bus (8-bit granularity assumed)
logic [N_SLAVE-1:0]              ms_stb_o; // strobe out, valid data transmission
logic                            ms_we_o;  // write enable

genvar ii;

// connect master signals to local signals
for(ii = 0; ii < N_MASTER; ii = ii + 1) begin
    // inputs
    assign ms_dat_i[ii]  = wb_master_bus[ii].wb_dat_o;
    assign ms_tgd_i[ii]  = wb_master_bus[ii].wb_tgd_o;
    assign ms_adr_i[ii]  = wb_master_bus[ii].wb_adr_o;
    assign ms_tga_i[ii]  = wb_master_bus[ii].wb_tga_o;
    assign ms_cyc_i[ii]  = wb_master_bus[ii].wb_cyc_o;
    assign ms_tgc_i[ii]  = wb_master_bus[ii].wb_tgc_o;
    assign ms_sel_i[ii]  = wb_master_bus[ii].wb_sel_o;
    assign ms_stb_i[ii]  = wb_master_bus[ii].wb_stb_o;
    assign ms_we_i[ii]   = wb_master_bus[ii].wb_we_o;
    assign mi_lock_i[ii] = wb_master_bus[ii].wb_lock_o;
    // outputs
    assign wb_master_bus[ii].wb_dat_i = sm_dat_o;
    assign wb_master_bus[ii].wb_tgd_i = sm_tgd_o;
    assign wb_master_bus[ii].wb_ack_i = sm_ack_o;
    assign wb_master_bus[ii].wb_err_i = sm_err_o;
    assign wb_master_bus[ii].wb_rty_i = sm_rty_o;
    assign wb_master_bus[ii].wb_gnt_i = im_gnt_o[ii];
end

// connect slave signals to local signals
for(ii = 0; ii < N_SLAVE; ii = ii + 1) begin
    // inputs
    assign sm_dat_i[ii] = wb_slave_bus[ii].wb_dat_o;
    assign sm_tgd_i[ii] = wb_slave_bus[ii].wb_tgd_o;
    assign sm_ack_i[ii] = wb_slave_bus[ii].wb_ack_o;
    assign sm_err_i[ii] = wb_slave_bus[ii].wb_err_o;
    assign sm_rty_i[ii] = wb_slave_bus[ii].wb_rty_o;
    // outputs
    assign wb_slave_bus[ii].wb_dat_i = ms_dat_o;
    assign wb_slave_bus[ii].wb_tgd_i = ms_tgd_o;
    assign wb_slave_bus[ii].wb_adr_i = ms_adr_o;
    assign wb_slave_bus[ii].wb_tga_i = ms_tga_o;
    assign wb_slave_bus[ii].wb_cyc_i = ms_cyc_o[ii];
    assign wb_slave_bus[ii].wb_tgc_i = ms_tgc_o;
    assign wb_slave_bus[ii].wb_sel_i = ms_sel_o;
    assign wb_slave_bus[ii].wb_stb_i = ms_stb_o[ii];
    assign wb_slave_bus[ii].wb_we_i  = ms_we_o;
end



logic [N_MASTER-1:0] master_arbiter_n;
logic [N_MASTER-1:0] master_arbiter_q;
logic [N_SLAVE-1:0]  slave_arbiter;
logic [31:0]         ms_adr;
logic                ms_cyc;
logic                ms_stb;

logic                locked_n;
logic                locked_q;

// Master arbiter select block
// sets master_arbiter to one-hot or 0
always_comb
begin
    master_arbiter_n = master_arbiter_q;

    // Free the bus if not used
    if((master_arbiter_q & ms_cyc_i) == 'b0) begin
        master_arbiter_n = 'b0;
        locked_n         = 1'b0;
    end

    // Give the bus to the highest priority (LSB) master
    for(int i = N_MASTER; i >= 0; i = i - 1) begin
        if(ms_cyc_i[i] && !locked_q) begin
            master_arbiter_n = 'b0 | (1 << i);
            locked_n         = mi_lock_i[i]; // lock the bus if requested
        end
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