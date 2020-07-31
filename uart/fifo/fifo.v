`timescale 1ns/1ps

module FIFO 
    #(
        parameter IN_DATA_WIDTH=32,         // Input data width
        parameter OUT_DATA_WIDTH=128,       // Output data width
        parameter DEPTH=8                   // FIFO depth
    )
(
    input clk,
    input rst_n,
    input [IN_DATA_WIDTH-1:0] data_i,       // Data IN
    input write_valid_i,                    // Data IN is valid
    input read_ready_i,                     // Someone from the outside wants to
                                            // read a word 

    output write_ready_o,                   // FIFO is ready to take in new data
    output read_valid_o,                    // DATA OUT is valid = FIFO has valid
                                            // word to be read
    output reg [OUT_DATA_WIDTH-1:0] data_o  // Data OUT
);

// Bitwidth of the counter variable
localparam COUNT_WIDTH = $clog2(DEPTH)+1;         
// Number elements which get combined to form one output element
localparam COMBINE = OUT_DATA_WIDTH / IN_DATA_WIDTH;
// Upper index for selecting the lower log2(COMBINE) bits of `count`
// (for determining the `read_valid_o`; see below)
// In case of `COMBINE`==1, we don't actually need to look at the
// lower bits of `count` at all. However, if we don't anything, then the bit
// range [0:0] (aka. LSB) of `count` will be considered falsely, leading
// to `read_valid_o` being asserted for only every two words. Therefore,
// below - where we assign to `read_valid_o` - we simply added a check if
// `COMBINE` is eq. to 1. This check gets OR'ed with the check of the lower
// bits of `combine`. If `COMBINE` happens to be 1, then the lower bits check
// is ignored and `read_valid_o` is assigned properly.
localparam INDEX = COMBINE==1 ? 0 : $clog2(COMBINE)-1;

// FIFO stages
reg [IN_DATA_WIDTH-1:0] mem [DEPTH-1:0];

// Counter for num of elements (each element is IN_DATA_WIDTH wide)
reg [COUNT_WIDTH-1:0] count;

// Pointer to the next readable output word
reg [COUNT_WIDTH-1:0] read_ptr;

// Handshake
wire write_hs;
wire read_hs;

// Init FIFO
integer i;
initial
begin
    count = 0;
    for(i=0;i<DEPTH;i=i+1)
        mem[i] = 0;
end

// Compute read pointer
/* verilator lint_off UNUSED */
reg [COUNT_WIDTH-1:0] count_tmp;
/* verilator lint_on UNUSED */
always @*
begin
    // Subtract 1 from count, since read_ptr is an index and needs to start from 0
    count_tmp = count - 1;
    // Replace the lower log2(COMBINE) bits of count_tmp with 0s
    read_ptr = { count_tmp[COUNT_WIDTH-1:$clog2(COMBINE)], {$clog2(COMBINE){1'b0}} };
end

// Set status signals
// Only allow write when FIFO not full AND no read happening
assign write_ready_o = ((count<DEPTH) && ~read_hs) ? 1'b1 : 1'b0;
// Allow read when FIFO not empty AND count%COMBINE==0; we
// can simplify the computation by just looking at the lower log2(COMBINE) bits of
// `count` and checking if they are all 0s (note that this only works for
// `COMBINE` values which are powers of 2, but that should be the case for us
// anyways)
//
// Check for `COMBINE`==1, because in that case, the lower bits of `count` don't
// matter (see above where localparam INDEX is defined for a more detailed
// explanation)
assign read_valid_o = (count>0 && ((count[INDEX:0]==0) || COMBINE==1)) ? 1'b1 : 1'b0;

// Compute handshake signals
assign write_hs = write_ready_o & write_valid_i;
assign read_hs = read_valid_o & read_ready_i;

// Write output
always @*
begin
    /* verilator lint_off WIDTH */
    for(i=COMBINE-1;i>=0;i=i-1) begin
        // We assume least-significant word gets shifted in first into FIFO
        // 
        // Example: COMBINE=4, read_ptr=0
        // After four words (w/ width=IN_DATA_WIDTH) have been pushed into
        // the FIFO, the FIFO memory looks as follows:
        // | mem[0] | mem[1] | mem[2] | mem[3] |
        // | word3  | word2  | word1  | word0  |
        // 
        // The data_o word (width=DATA_OUT_WIDTH = COMBINE*IN_DATA_WIDTH=
        // 4*IN_DATA_WIDTH) should be ordered as follows:
        // | MSB .................. LSB  |
        // | word3  word2  word1  word0  | =
        // | mem[0] mem[1] mem[2] mem[3] |
        data_o[i*IN_DATA_WIDTH +: IN_DATA_WIDTH] = mem[read_ptr+COMBINE-1-i];
    /* verilator lint_on WIDTH */
    end
end

// READ/WRITE process
// Reading and writing are controlled by the handshake signals
// Read has priority over Write
always @(posedge clk)
begin
    if(!rst_n)
        begin
            count <= 0;
        end
    else 
        begin
            // Read
            if(read_hs)
                begin
                    /* verilator lint_off WIDTH */
                    // Reduce `count` by how much elements we can read at once
                    count <= count - COMBINE;
                    /* verilator lint_on WIDTH */
                end
            // Write
            else if(write_hs)
                begin
                    // Shift in input word and increment `count`
                    mem[0] <= data_i;
                    for(i=0;i<DEPTH-1;i=i+1)
                        mem[i+1] <= mem[i];
                    count <= count + 1;
                end
        end

end




endmodule