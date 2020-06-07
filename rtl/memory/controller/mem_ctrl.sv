// ---------------RISCV-Luca---------------
// 
// Module:          mem_ctrl
// 
// Functionality:   memory controller
// 
// -------------(c) Luca Hanel-------------

module mem_ctrl
#(
    parameter BITSIZE = 32,
    parameter N_WORDS_PER_ADDR = 4,
    parameter MEM_SIZE = 1024,
    parameter N_ACCESSORS = 2 //Core, Cache
)(
    input                                       clk,
    input                                       resetn_i,
    //ACCESSORS
    input [(32 * N_ACCESSORS) - 1 : 0]          acc_address_i,
    input [N_ACCESSORS - 1 : 0]                 acc_store_i,
    input [N_ACCESSORS - 1 : 0]                 acc_load_i,
    /* verilator lint_off ALWCOMBORDER */
    /* verilator lint_off UNOPTFLAT */
    input [(N_ACCESSORS * N_WORDS_PER_ADDR * BITSIZE) - 1:0]  acc_data_i,
    output [(N_ACCESSORS * N_WORDS_PER_ADDR * BITSIZE) - 1:0]  acc_data_o,
    /* verilator lint_on UNOPTFLAT */
    /* verilator lint_on ALWCOMBORDER */
    output [N_ACCESSORS - 1 : 0]                acc_done_o,
    //Memory
    output [31 : 0]                             mem_addr_o,
    /* verilator lint_off ALWCOMBORDER */
    /* verilator lint_off UNOPTFLAT */
    input [(N_WORDS_PER_ADDR * BITSIZE) - 1:0]  mem_data_i,
    output [(N_WORDS_PER_ADDR * BITSIZE) - 1:0] mem_data_o,
    /* verilator lint_on ALWCOMBORDER */
    /* verilator lint_on UNOPTFLAT */
    output                                      mem_store_o,
    output                                      mem_valid_o,
    input                                       mem_valid_i
);

enum {IDLE, LOAD, STORE} CS, NS;

int                                         i;
/* verilator lint_off UNUSED */
int                                         accessor;
/* verilator lint_on UNUSED */

    /* verilator lint_off UNOPTFLAT */
logic [(N_WORDS_PER_ADDR * BITSIZE) - 1:0]  write_data;
    /* verilator lint_on UNOPTFLAT */
logic                                       mem_write_enable;

// MEMCTRL->MEM
assign mem_data_o = write_data;

//MEMCTRL -> ACCESSOR
genvar ii;
for(ii = 0; ii < N_ACCESSORS; ii = ii + 1) begin
    assign acc_data_o[((ii+1) * N_WORDS_PER_ADDR * BITSIZE) - 1 : (ii * N_WORDS_PER_ADDR * BITSIZE)] = write_data;
end

always_ff@(posedge clk)
begin
    if(!resetn_i)
    begin
        
    end
    else
    begin
        CS <= NS;
    end
end


for(ii = 0; ii < N_ACCESSORS; ii = ii + 1) begin
always_comb
begin
    acc_done_o = 'b0;
    mem_valid_o = 1'b0;
    mem_store_o = 1'b0;
    mem_write_enable = 1'b0;

    case(CS)
        IDLE: begin
            // Prefer store over load
            if(acc_store_i != '0)
            begin
                // Priority: First is highest
                for(i = N_ACCESSORS - 1; i >= 0; i = i - 1) begin
                    if(acc_store_i[i] == 'b1) begin
                        accessor = i;
                        NS = STORE;
                    end
                end
            end
            else
            if(acc_load_i != '0)
            begin
                // Priority: First is highest
                for(i = N_ACCESSORS - 1; i >= 0; i = i - 1) begin
                    if(acc_load_i[i] == 'b1) begin
                        accessor = i;
                        NS = LOAD;
                    end
                end
            end
        end

        LOAD: begin
            mem_valid_o = 1'b1;

            if(accessor == ii)
            begin
                mem_addr_o = acc_address_i[((ii+1) * BITSIZE) - 1 : (ii * BITSIZE)];
                write_data = mem_data_i;
            end
            if(mem_valid_i)
            begin
                acc_done_o[accessor] = 1'b1;
                NS = IDLE;
            end
            if(!acc_load_i[accessor])
            begin
                NS = IDLE;
            end
        end

        STORE: begin
            mem_write_enable = 1'b1;
            mem_valid_o = 1'b1;
            mem_store_o = 1'b1;
            if(accessor == ii)
            begin
                mem_addr_o = acc_address_i[((ii+1) * BITSIZE) - 1 : (ii * BITSIZE)];
                write_data = acc_data_i[((ii+1) * N_WORDS_PER_ADDR * BITSIZE) - 1 : (ii * N_WORDS_PER_ADDR * BITSIZE)]; 
            end
            if(mem_valid_i)
            begin
                acc_done_o[accessor] = 1'b1;
                NS = IDLE;
            end
            if(!acc_load_i[accessor])
            begin
                NS = IDLE;
            end
        end

        default:begin
        end
    endcase
end
end
endmodule