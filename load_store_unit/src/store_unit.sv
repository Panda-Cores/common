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
// Module name: store_unit
//
// Authors: Luca Hanel
// 
// Functionality: Connects to a wishbone bus and stores data
//
// TODO: 
//
// ------------------------------------------------------------

module store_unit
(
    input logic                        clk,
    input logic                        rstn_i,
    input logic                        write_i,
    input logic [31:0]                 addr_i,
    input logic [31:0]                 data_i,
    input logic [3:0]                  we_i,
    output logic                       valid_o,
    wb_bus_t.master                    wb_bus
);

enum logic {IDLE, WRITE} CS, NS;


logic [31:0]        wb_adr_o;  // address out
logic               wb_ack_i;  // acknowledge from slave
logic               wb_cyc_o;  // transaction cycle in progress
logic [3:0]         wb_sel_o;  // select where the data on the data bus (8-bit granularity assumed)
logic               wb_stb_o;  // strobe out, valid data transfer. Slave responds with ack, err or retry to assertion
logic               wb_gnt_i;  // Bus granted by interconnect

// local variables to wishbone bus (just dont want to rewrite everything ':D)
// assign wb_dat_i     = wb_bus.wb_dat_i;
// assign wb_tgd_i     = wb_bus.wb_tgd_i;
assign wb_ack_i     = wb_bus.wb_ack;
// assign wb_err_i     = wb_bus.wb_err_i;
// assign wb_rty_i     = wb_bus.wb_rty_i;
assign wb_gnt_i     = wb_bus.wb_gnt;
assign wb_bus.wb_sel     = wb_sel_o;
assign wb_bus.wb_stb     = wb_stb_o;
assign wb_bus.wb_we      = write_i;
assign wb_bus.wb_lock    = 'b0;
assign wb_bus.wb_cyc     = wb_cyc_o;
assign wb_bus.wb_tgc     = 'b0;
assign wb_bus.wb_dat_ms     = data_i;
assign wb_bus.wb_tgd_ms     = 'b0;
assign wb_bus.wb_adr     = addr_i;
assign wb_bus.wb_tga     = 'b0;

// State machine for wb master
always_comb
begin
    NS = CS;

    wb_cyc_o = 1'b0;
    valid_o = 1'b0;
    wb_stb_o = 1'b0;
    wb_sel_o = 4'b0;

    case(CS)
        IDLE: begin
            if(write_i) begin
                wb_cyc_o = 1'b1;
                NS = WRITE;
            end
        end

        WRITE: begin
            wb_cyc_o = 1'b1;
            if(wb_gnt_i) begin
                wb_stb_o = 1'b1;
                wb_sel_o = we_i;
                if(wb_ack_i) begin
                    valid_o = 1'b1;
                    if(!write_i)
                        NS = IDLE;
                end
            end
        end
    endcase
end

always_ff @(posedge clk, negedge rstn_i)
begin
    if(!rstn_i) begin
        CS <= IDLE;
    end else begin
        if(write_i)
            CS <= NS;
        else 
            CS <= IDLE;
    end
end

endmodule