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
// Module name: wishbone_master
// 
// Functionality: My try at a wishbone master with a simple
//                interface. This master only support single
//                READ & WRITE operations.
//
// TODO: enable the possibility of block read&writes. This makes
//       way for caches
//
// ------------------------------------------------------------

module wishbone_master #(
    parameter TAGSIZE = 2
)(
    input logic                     clk_i,
    input logic                     rst_i,
    input logic [31:0]              data_i,
    output logic [31:0]             data_o,
    input logic [31:0]              addr_i,
    input logic [3:0]               we_i,
    input logic                     valid_i,
    output logic                    valid_o,
    // Wishbone specifics
    // Data
    input logic [31:0]              wb_dat_i,  // data in
    input logic [TAGSIZE-1:0]       wb_tgd_i,  // data in tag 
    output logic [31:0]             wb_dat_o,  // data out
    output logic [TAGSIZE-1:0]      wb_tgd_o,  // data out tag
    // Address
    output logic                    wb_adr_o,  // address out
    output logic [TAGSIZE-1:0]      wb_tga_o,  // address tag
    // Sync
    input logic                     wb_ack_i,  // acknowledge from slave
    output logic                    wb_cyc_o,  // transaction cycle in progress
    output logic [TAGSIZE-1:0]      wb_tgc_o,  // transaction cycle tag
    input logic                     wb_err_i,  // slave encountered error
    output logic                    wb_lock_o, // lock the interconnect
    input logic                     wb_rty_i,  // retry request from slave
    output logic [3:0]              wb_sel_o,  // select where the data on the data bus (8-bit granularity assumed)
    output logic                    wb_stb_o,  // strobe out, valid data transfer. Slave responds with ack, err or retry to assertion
    output logic                    wb_we_o,   // write enable
    // Sync between mutliple masters (is this still in the spec? Somehow yes and no...)
    input logic                     wb_gnt_i
);

logic enum {IDLE, WRITE, READ} CS, NS;

always_ff @(posedge clk_i, posedge rst_i) begin
    if(rst_i) begin
        CS <= IDLE;
    end else begin
        CS <= NS;
    end
end

always_comb
begin
    wb_cyc_o = 1'b0;
    wb_we_o  = 1'b0;
    wb_dat_o = 'b0;
    wb_adr_o = 'b0;
    valid_o  = 1'b0;

    case(CS)
        IDLE: begin
            // Wait for a requested transaction
            if(valid_i) begin
                wb_cyc_o = 1'b1;    // assert that we want to perform a transaction
                if(wb_gnt_i) begin  // and wait for interconnect to grant us the bus
                    if(we_i != 'b0)
                        NS = WRITE;
                    else
                        NS = READ;
                end
            end
        end

        WRITE: begin
            // Assert cyc, stb and we
            wb_cyc_o = 1'b1;
            wb_stb_o = 1'b1;
            wb_we_o  = 1'b1;
            // Same granularity as write request
            wb_sel_o = we_i;
            // Assert address and data
            wb_adr_o = addr_i;
            wb_dat_o = data_i;
            // When slave acknowledges the write, we return to idle and validate the write request
            if(wb_ack_i) begin
                NS      = IDLE
                valid_o = 1'b1;
            end
        end

        READ: begin        
            // Assert cyc and stb    
            wb_cyc_o = 1'b1;
            wb_stb_o = 1'b1;
            // Same granularity as read request
            wb_sel_o = we_i;
            // Assert address
            wb_adr_o = addr_i;
            // When slave acknowledge the read, return to idle and validate read request
            if(wb_ack_i) begin
                NS      = IDLE
                valid_o = 1'b1;
                data_o  = wb_dat_i;
            end
        end

        default: begin
            NS = IDLE;
        end
    endcase
end

endmodule