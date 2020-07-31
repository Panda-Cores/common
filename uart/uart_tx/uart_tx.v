`timescale 1ns/1ns

module uart_tx
(
    input clk,
    input rst_n,
    input baud_clk,             // Sampling clock
    input [7:0] tx_data_i,      // The byte we want to transmit
    input tx_data_valid,        // Whether the value of tx_data_i is valid
    output reg tx,              // UART TX
    output tx_busy,             // Indicates whether transmission is ongoing
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

    // FSM state reg
    (* mark_debug = "true" *) reg [7:0] tx_fsm_state;
    reg [7:0] tx_fsm_state_next;
    
    // Data bit counter
    reg [3:0] tx_bit_cnt;

    // Sample counter
    reg [3:0] sample_cnt;

    // Input data reg
    reg [7:0] tx_data_reg;

    // FSM state transition
    always @(posedge clk)
    begin
        if(!rst_n)
            tx_fsm_state <= FSM_IDLE;
        else begin
            tx_fsm_state <= tx_fsm_state_next;
        end
    end
    
    // Sample counter
    always @(posedge clk)
    begin
        if(!rst_n || (tx_fsm_state==FSM_IDLE))
            sample_cnt <= 4'd0;
        else if(baud_clk==1'b1) // Start counting sampling ticks when transmission started
            sample_cnt <= sample_cnt + 1;
        else
            sample_cnt <= sample_cnt;
    end

    // Next state logic
    always @*
    begin
        case(tx_fsm_state)
            FSM_IDLE: begin
                // Valid byte to be TX'ed has arrived
                if(tx_data_valid == 1'b1) begin
                    tx_fsm_state_next = FSM_START_BIT; 
                end else begin
                    tx_fsm_state_next = FSM_IDLE; 
                end
            end
            FSM_START_BIT: begin
                // Hold TX=LOW for 16 sampling periods = 1 baud period
                // We check for baud_clk==1 here, because we want the transition
                // to happen synchronously with the baud sample pulse as well
                if(baud_clk==1'b1 && sample_cnt==4'd15) begin
                    tx_fsm_state_next = FSM_DATA_BITS; 
                end else begin
                    tx_fsm_state_next = FSM_START_BIT;
                end
            end
            FSM_DATA_BITS: begin
                // Wait until all 8 bits have been TX'ed
                if(baud_clk==1'b1 && tx_bit_cnt == 4'd8) begin
                    tx_fsm_state_next = FSM_STOP_BIT; 
                end else begin
                    tx_fsm_state_next = FSM_DATA_BITS; 
                end
            end
            FSM_STOP_BIT: begin
                // Hold TX=1 for 16 sampling periods = 1 baud period
                // TODO: Is this really necessary? After STOP_BIT state
                // we go back to IDLE which also pulls TX to HIGH.
                if(baud_clk==1'b1 && sample_cnt == 4'd15) begin
                    tx_fsm_state_next = FSM_IDLE;
                end else begin
                    tx_fsm_state_next = FSM_STOP_BIT;
                end 
            end
            default: begin
                // Default to IDLE
                tx_fsm_state_next = FSM_IDLE;
            end
        endcase    
    end

    // `tx_data_reg` stuff
    always @(posedge clk) begin
        if(!rst_n) begin
            tx_data_reg <= 8'b0;
        end else begin
            // Only latch in if valid and not TX'ing
            // (Because tx_data_reg is needed during TX!)
            if(tx_data_valid && ~tx_busy) begin
                tx_data_reg <= tx_data_i;
            // Shift
            // Also make sure we have send out at least 1 bit, otherwise the shift would
            // happen already after the startbit
            end else if(baud_clk==1'b1 && tx_fsm_state==FSM_DATA_BITS && sample_cnt==4'd0 && tx_bit_cnt>=1) begin
                // The LSB is put on the TX line (see TX output process)
                tx_data_reg <= tx_data_reg>>1;
            end else begin
                tx_data_reg <= tx_data_reg; 
            end
        end 
    end

    // TX bit counter
    always @(posedge clk)
    begin
        // Reset counter on reset; Don't count when we are not TX'ing
        if(!rst_n || tx_fsm_state!=FSM_DATA_BITS)
            tx_bit_cnt <= 4'd0;
        else if(baud_clk==1'b1 && tx_fsm_state==FSM_DATA_BITS && sample_cnt==4'd15) begin
            // Counter will increment at end of each bit
            tx_bit_cnt <= tx_bit_cnt + 1;
        end else begin
            tx_bit_cnt <= tx_bit_cnt; 
        end
    end

    // TX output
    always @*
    begin
        // Pull TX to HIGH when nothing is being TX'ed
        if(tx_fsm_state==FSM_IDLE || tx_fsm_state==FSM_STOP_BIT) begin
            tx = 1'b1;
        // Pull TX to LOW for START bit
        end else if(tx_fsm_state==FSM_START_BIT) begin
            tx = 1'b0;
        // Put next data bit onto TX line
        end else if(tx_fsm_state==FSM_DATA_BITS) begin
            tx = tx_data_reg[0];
        end else begin
            tx = 1'b1; 
        end
    end

    // Signal busy when not in IDLE
    assign tx_busy = tx_fsm_state==FSM_IDLE ? 1'b0 : 1'b1;

    // Disable baudgen during IDLE
    assign baud_rst = tx_fsm_state==FSM_IDLE;

endmodule