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
// Module name: timer
//
// Authors: Luca Hanel
// 
// Functionality: A timer
//
// TODO: 
//
// ------------------------------------------------------------

`inclue "timer_incl.sv"

module timer(
    input logic             clk,
    input logic             rstn_i,
    output logic            cmp_interrupt_o,
    output logic            of_interrupt_o,
    wb_bus_t.slave          wb_bus
);

logic [31:0]    timer_regs_q[3]

logic [31:0]    timer_incr;

// WB slave
always_comb
begin
    wb_bus.wb_ack = 1'b0;

    if(wb_bus.wb_cyc && wb_bus.wb_stb) begin
        wb_bus.wb_ack = 1'b1;
        if(wb_bus.wb_adr > 31'd12)
            // If the address is out of bounds, return error
            wb_bus.wb_err = 1'b1;
        else begin
            if(wb_bus.wb_we) begin
                // Writing
                if(wb_bus.sel[0])
                    timer_regs_q[wb_bus.wb_adr[31:2]][7:0] = wb_bus.wb_dat_ms[7:0];
                if(wb_bus.sel[1])
                    timer_regs_q[wb_bus.wb_adr[31:2]][15:8] = wb_bus.wb_dat_ms[15:8];
                if(wb_bus.sel[2])
                    timer_regs_q[wb_bus.wb_adr[31:2]][23:16] = wb_bus.wb_dat_ms[23:16];
                if(wb_bus.sel[3])
                    timer_regs_q[wb_bus.wb_adr[31:2]][31:24] = wb_bus.wb_dat_ms[31:24];
            end else begin
                // Reading (only supports full 32 bit reading)
                wb_bus.wb_dat_sm = timer_regs_q[wb_bus.wb_adr[31:2]];
            end
        end
    end
end

// Timer
always_comb
begin
    timer_incr = 31'b0;
    cmp_interrupt_o = 1'b0;
    of_interrupt_o = 1'b0;

    // only operate if enabled
    if(timer_regs_q[`CFG][`ENABLE_BIT]) begin
        // timer increment
        timer_incr = 31'b1 << timer_regs_q[`CFG][`PRSC_START:`PRSC_END];

        // compare interrupt
        if(timer_regs_q[`TIMER] > timer_regs_q[`CMP])
            cmp_interrupt_o = 1'b1;

        // overflow interrupt
        if(timer_regs_q[`TIMER] > (timer_regs_q[`TIMER] + timer_incr))
            of_interrupt_o = 1'b1;
    end

end

always_comb
begin
    if(!rstn_i) begin
        timer_regs_q <= 'b0;
    end else begin
        timer_regs_q[`TIMER] <= timer_regs_q[`TIMER] + timer_incr;
    end
end

endmodule