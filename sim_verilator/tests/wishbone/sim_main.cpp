#include <verilated.h>
#include "Vwishbone_tb.h"

#if VM_TRACE
# include <verilated_vcd_c.h>
#endif

static int t_cnt = 0;
static Vwishbone_tb* top = new Vwishbone_tb;
VerilatedVcdC* tfp = new VerilatedVcdC;

int write_test(int addr, int data){
    t_cnt++;
    top->eval();
    tfp->dump(t_cnt);
    top->clk = !top->clk;
    t_cnt++;
    top->eval();
    tfp->dump(t_cnt);
    top->clk = !top->clk;
    int count = 0;
    top->m0data_i = data;
    top->m0valid_i = 1;
    top->m0we_i = 0b1111;
    top->m0addr_i = addr;
    while(top->m0valid_o != 1 && count < 10){
        t_cnt++;
        top->eval();
        tfp->dump(t_cnt);
        top->clk = !top->clk;
        count++;
    }
    top->m0valid_i = 0;
    return 0;
}

int read_test(int addr, int expected_data){
    t_cnt++;
    top->eval();
    tfp->dump(t_cnt);
    top->clk = !top->clk;
    t_cnt++;
    top->eval();
    tfp->dump(t_cnt);
    top->clk = !top->clk;
    int count = 0;
    top->m0valid_i = 1;
    top->m0we_i = 0b0000;
    top->m0addr_i = addr;
    while(top->m0valid_o != 1 && count < 10){
        t_cnt++;
        top->eval();
        tfp->dump(t_cnt);
        top->clk = !top->clk;
        count++;
    }
    top->m0valid_i = 0;
    if(top->m0data_o != expected_data)
        return top->m0data_o;
    return 0;
}

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    int result;
    
    Verilated::traceEverOn(true);
    top->trace(tfp, 99);  // Trace 99 levels of hierarchy
    Verilated::mkdir("logs");
    tfp->open("logs/vlt_dump.vcd");  // Open the dump file
    
    // Reset the core
    top->clk = 0;
    top->rstn_i = 0;
    for(int i = 0; i < 5; i++){
        t_cnt++;
        top->eval();
        tfp->dump(t_cnt);
        top->clk = !top->clk;
    }
    top->rstn_i = 1;

    // Run tests
    write_test(0x0, 0xababcdcd);
    write_test(0x4, 0xababcdcd);
    write_test(0x8, 0xababcdcd);
    write_test(0xc, 0xababcdcd);
    write_test(0x10, 0xababcdcd);
    write_test(0x14, 0xababcdcd);
    if(result = read_test(0x0, 0xababcdcd) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;

    if(result = read_test(0x4, 0xababcdcd) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;

    if(result = read_test(0x8, 0xababcdcd) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;

    if(result = read_test(0xc, 0xababcdcd) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;
    

    if(result = read_test(0x10, 0xababcdcd) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;
    

    if(result = read_test(0x14, 0xababcdcd) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;
    

    for(int i = 0; i < 4; i++){
        t_cnt++;
        top->eval();
        tfp->dump(t_cnt);
        top->clk = !top->clk;
    }

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
