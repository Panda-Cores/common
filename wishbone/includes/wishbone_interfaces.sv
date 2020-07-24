/* verilator lint_off DECLFILENAME */
/* verilator lint_off MODDUP */
interface wb_master_bus_t #(parameter TAGSIZE=2);
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
endinterface //wb_master_bus

interface wb_slave_bus_t #(parameter TAGSIZE=2);
    logic [31:0]        wb_dat_i;  // data in
    logic [TAGSIZE-1:0] wb_tgd_i;  // data in tag 
    logic [31:0]        wb_dat_o;  // data out
    logic [TAGSIZE-1:0] wb_tgd_o;  // data out tag
    logic [31:0]        wb_adr_i;  // address out
    logic [TAGSIZE-1:0] wb_tga_i;  // address tag
    logic               wb_ack_o;  // acknowledge to master
    logic               wb_cyc_i;  // transaction cycle in progress
    logic [TAGSIZE-1:0] wb_tgc_i;  // transaction cycle tag
    logic               wb_err_o;  // slave encountered error
    logic               wb_rty_o;  // retry request from slave
    logic [3:0]         wb_sel_i;  // select where the data on the data bus (8-bit granularity assumed)
    logic               wb_stb_i;  // strobe out, valid data transfer. Slave responds with ack, err or retry to assertion
    logic               wb_we_i;   // write enable
endinterface //wb_slave_bus
/* verilator lint_on DECLFILENAME */
/* verilator lint_on MODDUP */