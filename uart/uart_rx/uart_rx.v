`timescale 1ns/1ns

module uart_rx
(
    input clk,
    input rst_n,
    input rx,                   // UART RX
    input baud_clk,             // Sampling clock
    output reg [7:0] rx_data_o, // Received byte out
    output reg rx_data_valid,   // Whether the value at rx_data_o is valid
    output baud_rst             // For disabling baudgen during IDLE
);
    // Start & Stop bit defines for better readability
    localparam START = 1'b0;
    localparam STOP = 1'b1;

    // FSM states
    localparam FSM_IDLE = 8'd0;
    localparam FSM_START_BIT = 8'd1;
    localparam FSM_DATA_BITS = 8'd2;
    localparam FSM_STOP_BIT = 8'd4;
    localparam FSM_DONE = 8'd8;
    localparam FSM_ERR = 8'd16;

    // FSM state regs
    (* mark_debug = "true" *) reg [7:0] rx_fsm_state;
    reg [7:0] rx_fsm_state_next;

    // Data bit shift reg
    reg [7:0] data_bits;

    // Data bit counter
    reg [3:0] rx_bit_cnt;

    // Sample counter
    reg [3:0] sample_cnt;

    // FSM state transition
    always @(posedge clk)
    begin
        if(!rst_n)
            rx_fsm_state <= FSM_IDLE;
        else begin
            rx_fsm_state <= rx_fsm_state_next;
        end
    end

    // Sample counter
    always @(posedge clk)
    begin
        // Reset counter on reset OR FSM is IDLE 
        if(!rst_n || (rx_fsm_state==FSM_IDLE /*&& rx==START*/))
            sample_cnt <= 4'd0;
        else if(baud_clk==1'b1)
            sample_cnt <= sample_cnt + 1;
        else
            sample_cnt <= sample_cnt;
    end

    // Next state logic
    always @*
    begin
        case (rx_fsm_state)
            FSM_IDLE: begin
                // Start bit has been received
                if(rx == START) begin
                   rx_fsm_state_next = FSM_START_BIT; 
                end else begin
                   rx_fsm_state_next = FSM_IDLE; 
                end
            end
            FSM_START_BIT: begin
                // Wait for a full baud period for synchronization
                // We check for baud_clk==1 here, because we want the transition
                // to happen synchronously with the baud sample pulse as well
                if(baud_clk==1'b1 && sample_cnt==4'd15) begin
                    rx_fsm_state_next = FSM_DATA_BITS;
                end else if(rx==START) begin
                    // Stay in START_BIT state if RX line still LOW
                    rx_fsm_state_next = FSM_START_BIT;
                end else begin
                    // Go back to IDLE if START bit was too short
                    rx_fsm_state_next = FSM_IDLE; 
                end
            end
            FSM_DATA_BITS: begin
                // Receive/Sample 8 data bits
                if(baud_clk==1'b1 && rx_bit_cnt==4'd8) begin
                    rx_fsm_state_next = FSM_STOP_BIT;
                end else begin
                    rx_fsm_state_next = FSM_DATA_BITS; 
                end
            end
            FSM_STOP_BIT: begin
                // Wait for one baud period of STOP bit
                if(baud_clk==1'b1 && sample_cnt==4'd15) begin
                    rx_fsm_state_next = FSM_DONE;
                end else if(rx==STOP) begin
                    rx_fsm_state_next = FSM_STOP_BIT;
                end else begin
                    // If STOP bit was too short, go to error state
                    rx_fsm_state_next = FSM_ERR; 
                end
            end
            FSM_DONE: begin
                // Jump back to IDLE after one cycle
                rx_fsm_state_next = FSM_IDLE;
            end
            FSM_ERR: begin
                // In case of error, trap here
                rx_fsm_state_next = FSM_ERR;
            end
            default: begin
                // Default to IDLE
                rx_fsm_state_next = FSM_IDLE; 
            end
        endcase
    end

    // RX bit counter
    always @(posedge clk)
    begin
        // Reset counter when stop bit has been received
        if(!rst_n || rx_fsm_state==FSM_STOP_BIT)
            rx_bit_cnt <= 4'd0;
        // Increment counter during RX at end of each data bit
        else if(baud_clk==1'b1 && rx_fsm_state==FSM_DATA_BITS && sample_cnt==4'd15) begin
            rx_bit_cnt <= rx_bit_cnt + 1;
        end else begin
            rx_bit_cnt <= rx_bit_cnt; 
        end
    end

    // Sample RX data bits 
    always @(posedge clk)
    begin
        // Check if sample point (= middle of data bit) has been reached
        if(baud_clk==1'b1 && rx_fsm_state==FSM_DATA_BITS && sample_cnt==4'd7) begin
            data_bits <= { data_bits[6:0], rx };
        end else begin
            data_bits <= data_bits; 
        end
    end

    // Write to output reg
    always @*
    begin
        // In DONE state, the received byte is presented for one cycle
        // at the rx_data_o output.
        // The order of the data_bits is due to the following:
        //      1) Data bits arrive LSB-first
        //      2) We shift in the sampled bits at the LSB-side of data_bits
        //         (see Sampling process above)
        rx_data_o = {data_bits[0], data_bits[1], data_bits[2], data_bits[3], data_bits[4], data_bits[5], data_bits[6], data_bits[7]};
        if(rx_fsm_state == FSM_DONE) begin
            rx_data_valid = 1;
        // Only present data when in DONE state
        end else begin
            // rx_data_o = 8'b0; // For now don't explicitly set data to 0, to save switching activity
            rx_data_valid = 0;
        end
    end

    // Disable baudgen during IDLE
    assign baud_rst = rx_fsm_state==FSM_IDLE;

endmodule