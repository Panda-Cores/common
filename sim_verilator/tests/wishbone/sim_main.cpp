#include <verilated.h>
#include "Vwishbone_tb.h"

#if VM_TRACE
# include <verilated_vcd_c.h>
#endif

static Vwishbone_tb* top = new Vwishbone_tb;

int write_test(int addr, int data){
    top->m0data_i = data;
    top->m0valid_i = 1;
    top->m0we_i = 0b1111;
    top->m0addr_i = addr;
    while(top->valid_o != 1){
        for(int i = 0; i < 2; i++)
            top->clk = !top->clk;
    }
    return 0;
}

int read_test(int addr, int expected_data){
    top->m0valid_i = 1;
    top->m0we_i = 0b0000;
    top->m0addr_i = addr;
    while(top->valid_o != 1){
        for(int i = 0; i < 2; i++)
            top->clk = !top->clk;
    }
    if(top->m0data_o != expected_data)
        return top->m0data_o;
    return 0;
}

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    int result;
    
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);  // Trace 99 levels of hierarchy
    Verilated::mkdir("logs");
    tfp->open("logs/vlt_dump.vcd");  // Open the dump file
    
    // Reset the core
    int clk = 0;
    top->clk = 0;
    top->rstn_i = 0;
    for(clk = 0; clk < 5; clk++){
        top->eval();
        tfp->dump(clk);
        top->clk = !top->clk;
    }
    top->rstn_i = 1;

    // Run tests
    write_test(0x1, 0xababcdcd);
    if(result = read_test(0x1, 0xababcdcd) != 0)
        std::cout << 'FAILED ' << result << std::endl;
    // Final model cleanup
    top->final();

    // Close trace if opened
    if (tfp) { tfp->close(); tfp = NULL; }

    //  Coverage analysis (since test passed)
#if VM_COVERAGE
    Verilated::mkdir("logs");
    VerilatedCov::write("logs/coverage.dat");
#endif

    // Destroy model
    delete top; top = NULL;

    // Fin
    exit(0);
}
