#include <verilated.h>
#include "Vlsu_tb.h"
#include "testbench.h"

typedef unsigned __int128 uint128_t;

TESTBENCH<Vlsu_tb> *tb;

void write(int addr, int data, int sel){
    tb->m_core->write_i = 1;
    tb->m_core->read_i = 0;
    tb->m_core->we_i = sel;
    tb->m_core->addr_i = addr;
    tb->m_core->data_i = data;
    tb->tick();
    while((tb->m_core->valid_o) == 0){
        tb->tick();
    }
    tb->m_core->write_i = 0;
    tb->m_core->we_i = 0;
}

int read(int addr){
    tb->m_core->write_i = 0;
    tb->m_core->read_i = 1;
    tb->m_core->addr_i = addr;
    tb->tick();
    while((tb->m_core->valid_o) == 0){
        tb->tick();
    }
    tb->m_core->read_i = 0;
    return (uint32_t) (tb->m_core->data_o);
}

int test_lsu(){
    // Write with one master, read with the other and the other way around
    for(int i = 0; i < 0x80; i+=4){
        write(i, (0xababcd00 + i), 0b1111);
        tb->tick();
        if(read(i) != (0xababcd00 + i))
            return i+1;
        tb->tick();
    }

    return 0;
}
int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    tb = new TESTBENCH<Vlsu_tb>();
    tb->opentrace("logs/trace.vcd");
    int result = 0;

    // Initialize inputs
    tb->m_core->write_i = 0;
    tb->m_core->read_i = 0;
    tb->m_core->addr_i = 0;
    tb->m_core->data_i = 0;

    // Reset
    tb->reset();

    // Run tests
    result = test_lsu();
    
    // Cleanup
    tb->tick();
    tb->m_core->final();

    // Evaluate test
    if(result == 0)
        std::cout << "PASSED" << std::endl;
    else
        std::cout << "FAILED " << result << std::endl;
    
    //  Coverage analysis (since test passed)
    VerilatedCov::write("logs/coverage.dat");

    // Destroy model
    delete tb->m_core; tb->m_core = NULL;

    exit(0);
}
