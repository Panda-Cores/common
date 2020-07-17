#include <verilated.h>
#include "Vwishbone_tb.h"

#if VM_TRACE
# include <verilated_vcd_c.h>
#endif

static int t_cnt = 0;
static Vwishbone_tb* top = new Vwishbone_tb;
VerilatedVcdC* tfp = new VerilatedVcdC;

int write_test(int master, int addr, int data){
    int count = 0;
    t_cnt++;
    top->eval();
    tfp->dump(t_cnt);
    top->clk = !top->clk;
    t_cnt++;
    top->eval();
    tfp->dump(t_cnt);
    top->clk = !top->clk;

    top->mdata_i = (uint64_t) data << (master * 32);
    top->mvalid_i = 1 << master;
    top->mwe_i = 0b1111 << (master * 4);
    top->maddr_i = (uint64_t) addr << (master * 32);
    while((top->mvalid_o & (1 << master)) == 0 && count < 10){
        t_cnt++;
        top->eval();
        tfp->dump(t_cnt);
        top->clk = !top->clk;
        count++;
    }
    top->mvalid_i = 0;
    return 0;
}

int read_test(int master, int addr, int expected_data){
    t_cnt++;
    top->eval();
    tfp->dump(t_cnt);
    top->clk = !top->clk;
    t_cnt++;
    top->eval();
    tfp->dump(t_cnt);
    top->clk = !top->clk;

    int count = 0;
    top->mdata_i = (uint64_t) 0 << (master * 32);
    top->mwe_i = 0b0 << (master * 4);
    top->mvalid_i = (1 << master);
    top->maddr_i = (uint64_t) addr << (master * 32);
    while((top->mvalid_o & (1 << master)) == 0 && count < 10){
        t_cnt++;
        top->eval();
        tfp->dump(t_cnt);
        top->clk = !top->clk;
        count++;
    }
    top->mvalid_i = 0;
    if((uint32_t) (top->mdata_o  >> (32*master)) != expected_data)
        return 1;
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
    write_test(0, 0x0, 0xababcdc1);
    write_test(0, 0x4, 0xababcdc2);
    write_test(0, 0x8, 0xababcdc3);
    write_test(0, 0xc, 0xababcdc4);
    write_test(0, 0x10, 0xababcdc5);
    write_test(0, 0x14, 0xababcdc6);
    if(result = read_test(0, 0x0, 0xababcdc1) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;

    if(result = read_test(0, 0x4, 0xababcdc2) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;

    if(result = read_test(0, 0x8, 0xababcdc3) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;

    if(result = read_test(0, 0xc, 0xababcdc4) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;
    

    if(result = read_test(0, 0x10, 0xababcdc5) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;
    
    if(result = read_test(0, 0x14, 0xababcdc6) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;


    write_test(1, 0x0, 0xababcd11);
    write_test(1, 0x4, 0xababcd12);
    write_test(1, 0x8, 0xababcd13);
    write_test(1, 0xc, 0xababcd14);
    write_test(1, 0x10, 0xababcd15);
    write_test(1, 0x14, 0xababcd16);
    if(result = read_test(1, 0x0, 0xababcd11) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;

    if(result = read_test(1, 0x4, 0xababcd12) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;

    if(result = read_test(1, 0x8, 0xababcd13) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;

    if(result = read_test(1, 0xc, 0xababcd14) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;    

    if(result = read_test(1, 0x10, 0xababcd15) != 0)
        std::cout << "FAILED " << result << std::endl;
    else
        std::cout << "PASSED " << result << std::endl;
    

    if(result = read_test(1, 0x14, 0xababcd16) != 0)
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
