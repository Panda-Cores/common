// ------------------------ Disclaimer -----------------------
// No warranty of correctness, synthesizability or 
// functionality of this code is given.
// Use this code under your own risk.
// When using this code, copy this disclaimer at the top of 
// your file
//
// (c) Luca Hanel 2020
//
// ------------------------------------------------------------
//
// Module name: wishbone_master
// 
// Functionality: My try at a wishbone master with a simple
//                interface. This master only support single
//                READ & WRITE operations.
//
// TODO: enable the possibility of block read&writes. This makes
//       way for caches
//       Possibly make use of tags
//       Rework the interface to accept commands
//
// ------------------------------------------------------------

module wishbone_master #(
    parameter TAGSIZE = 2,
    parameter N_ACCESS = 8
)(
/* verilator lint_off UNDRIVEN */
    input logic                         clk_i,
    input logic                         rst_i,
    input logic [31:0]                  data_i,
    output logic [31:0]                 data_o,
    input logic [31:0]                  addr_i,
    input logic [$clog2(N_ACCESS)-1:0]  n_access_i,
    input logic [3:0]                   we_i,
    input logic                         valid_i,
    output logic                        valid_o,
    wb_master_bus_t                     wb_bus
);


logic [31:0]        wb_dat_i;  // data in
logic [TAGSIZE-1:0] wb_tgd_i;  // data in tag 
logic [31:0]        wb_dat_o;  // data out
logic [TAGSIZE-1:0] wb_tgd_o;  // data out tag
logic [31:0]        wb_adr_o;  // address out
logic [TAGSIZE-1:0] wb_tga_o;  // address tag
logic               wb_ack_i;  // acknowledge from slave
logic               wb_cyc_o;  // transaction cycle in progress
logic [TAGSIZE-1:0] wb_tgc_o;  // transaction cycle tag
logic               wb_err_i;  // slave encountered error
logic               wb_lock_o; // lock the interconnect
logic               wb_rty_i;  // retry request from slave
logic [3:0]         wb_sel_o;  // select where the data on the data bus (8-bit granularity assumed)
logic               wb_stb_o;  // strobe out, valid data transfer. Slave responds with ack, err or retry to assertion
logic               wb_we_o;   // write enable
logic               wb_gnt_i;  // Bus granted by interconnect

// local variables to wishbone bus (just dont want to rewrite everything ':D)
assign wb_dat_i     = wb_bus.wb_dat_i;
assign wb_tgd_i     = wb_bus.wb_tgd_i;
assign wb_ack_i     = wb_bus.wb_ack_i;
assign wb_err_i     = wb_bus.wb_err_i;
assign wb_rty_i     = wb_bus.wb_rty_i;
assign wb_gnt_i     = wb_bus.wb_gnt_i;
assign wb_bus.wb_sel_o     = wb_sel_o;
assign wb_bus.wb_stb_o     = wb_stb_o;
assign wb_bus.wb_we_o      = wb_we_o;
assign wb_bus.wb_lock_o    = 'b0;
assign wb_bus.wb_cyc_o     = wb_cyc_o;
assign wb_bus.wb_tgc_o     = 'b0;
assign wb_bus.wb_dat_o     = wb_dat_o;
assign wb_bus.wb_tgd_o     = 'b0;
assign wb_bus.wb_adr_o     = wb_adr_o;
assign wb_bus.wb_tga_o     = 'b0;

enum logic [1:0] {IDLE, WRITE, READ} CS, NS;

logic [31:0]                 addr_n, addr_q;
logic [31:0]                 data_n, data_q;
logic [$clog2(N_ACCESS)-1:0] counter_n, counter_q;
logic                        incr_counter;

always_ff @(posedge clk_i, posedge rst_i)
begin
    if(rst_i) begin
        CS <= IDLE;
    end else begin
        CS <= NS;
        addr_q <= addr_n;
        data_q <= data_n;
        counter_q <= counter_n;
        if(incr_counter) begin
            addr_q <= addr_n + 4;
            counter_q <= counter_n + 1;
        end
    end
end

always_comb
begin
    NS       = CS;
    wb_cyc_o = 1'b0;
    wb_we_o  = 1'b0;
    wb_dat_o = 'b0;
    valid_o  = 1'b0;
    wb_sel_o = 'b0;
    wb_stb_o = 1'b0;

    incr_counter = 1'b0;
    addr_n = addr_q;
    wb_adr_o = addr_q;
    counter_n = counter_q;
    data_n = data_i;

    case(CS)
        IDLE: begin
            // Wait for a requested transaction
            if(valid_i) begin
                wb_adr_o = addr_i;
                addr_n   = addr_i;
                counter_n= 'b1;
                wb_cyc_o = 1'b1;        // assert that we want to perform a transaction
                if(we_i != 'b0)   // and jump into respective state
                    NS = WRITE;
                else
                    NS = READ;
            end
        end

        WRITE: begin
            // keep cyc asserted
            wb_cyc_o = 1'b1;
            if(wb_gnt_i) begin  // wait for interconnect to grant us the bus
                wb_stb_o = 1'b1;
                wb_we_o  = 1'b1;
                // Same granularity as write request
                wb_sel_o = we_i;
                // Assert data
                wb_dat_o = data_q;
                // When slave acknowledges the write, we return to idle and validate the write request
                if(wb_ack_i) begin
                    valid_o = 1'b1;
                    if(counter_q < n_access_i)
                        incr_counter = 1'b1;
                    else
                        NS = IDLE;
                end
            end
        end

        READ: begin        
            // keep cyc asserted
            wb_cyc_o = 1'b1;
            if(wb_gnt_i) begin  // wait for interconnect to grant us the bus
                wb_stb_o = 1'b1;
                // Same granularity as read request
                wb_sel_o = we_i;
                data_o   = wb_dat_i;
                // When slave acknowledge the read, return to idle and validate read request
                if(wb_ack_i) begin
                    valid_o = 1'b1;
                    if(counter_q < n_access_i)
                        incr_counter = 1'b1;
                    else
                        NS = IDLE;
                end
            end
        end

        default: begin
            NS = IDLE;
        end
    endcase
end

endmodule