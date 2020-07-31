`timescale 1ns/1ns

module baudgen
    #(
        parameter CLK_FREQ=1000000,
        parameter BAUD_RATE=9600
    )
(
    input clk,              // Input clock
    input rst,              // If this goes to HIGH, the baud clock is disabled.
    output reg baud_clk     // Generated baud clock. Incoming data bits are
                            // sampled with this clock.
);

    // TICK_COUNT*2 = Number of CLK periods in one baud_clk period
    // localparam TICK_COUNT = CLK_FREQ/(2*16*BAUD_RATE);   // Option 1 (see below)
    localparam TICK_COUNT = CLK_FREQ/(16*BAUD_RATE);        // Option 2  

    reg [31:0] counter;

    initial
    begin
        baud_clk = 1'b0;
        counter = 0;
    end

    // Option 1: Create baud clock with 50% duty cycle
    // always @(posedge clk)
    // begin
    //     if(counter == TICK_COUNT-1)
    //     begin
    //         counter <= 0;
    //         baud_clk <= ~baud_clk;
    //     end
    //     else
    //         counter <= counter + 1;
    // end
    
    // Option 2: Create baud clock pulses
    always @(posedge clk)
    begin
        if(rst || (counter==TICK_COUNT-1))
        begin
            counter <= 0;
        end
        else
            counter <= counter + 1;
    end

    always @*
    begin
        baud_clk = counter==(TICK_COUNT-1); 
    end

endmodule