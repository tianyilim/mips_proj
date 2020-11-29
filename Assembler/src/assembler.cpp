#include <iostream>
#include <cmath>
#include <string>
#include <vector>
#include <algorithm>
#include <map>
#include <bitset>

using namespace std;

map<string, uint32_t> Registers = {
    /*{"$zero", 0},
    {"$at", 1},
    {"$v0", 2},
    {"$v1", 3},
    {"$a0", 4},
    {"$a1", 5},
    {"$a2", 6},
    {"$a3", 7},
    {"$t0", 8},
    {"$t1", 9},
    {"$t2", 10},
    {"$t3", 11},
    {"$t4", 12},
    {"$t5", 13},
    {"$t6", 14},
    {"$t7", 15},
    {"$s0", 16},
    {"$s1", 17},
    {"$s2", 18},
    {"$s3", 19},
    {"$s4", 20},
    {"$s5", 21},
    {"$s6", 22},
    {"$s7", 23},
    {"$t8", 24},
    {"$t9", 25},
    {"$k0", 26},
    {"$k1", 27},
    {"$gp", 28},
    {"$sp", 29},
    {"$fp", 30},
    {"$ra", 31},
    */
    {"$0", 0},
    {"$1", 1},
    {"$2", 2},
    {"$3", 3},
    {"$4", 4},
    {"$5", 5},
    {"$6", 6},
    {"$7", 7},
    {"$8", 8},
    {"$9", 9},
    {"$10", 10},
    {"$11", 11},
    {"$12", 12},
    {"$13", 13},
    {"$14", 14},
    {"$15", 15},
    {"$16", 16},
    {"$17", 17},
    {"$18", 18},
    {"$19", 19},
    {"$20", 20},
    {"$21", 21},
    {"$22", 22},
    {"$23", 23},
    {"$24", 24},
    {"$25", 25},
    {"$26", 26},
    {"$27", 27},
    {"$28", 28},
    {"$29", 29},
    {"$30", 30},
    {"$31", 31}
};

uint32_t Construct_R_Type(int op, int rs, int rt, int rd, int shamt, int fc) {
    int32_t out = 0; //Declares our output, restricted to 32 bits.
    out = (op << 26); //Shifts it 26 bits (Pads with 6 0s which is the R type standard)
    out |= (rs << 21); //Fills it with next section RS, shifts again
    out |= (rt << 16); //Shifts with next argument register RT, shifts again
    out |= (rd << 11); //Adds destination register
    out |= (shamt << 6); //Adds shift amount, shifts again
    out |= fc; //Ends with fc which is already 0 by default, our R type requirement //
    return out; //Returns the complete binary sequence
}
uint32_t Construct_I_Type(int op, int rs, int rd, int immediate) {
    //For the I type instruction, I have to shift by the opcode just like before, shift rs and rd, but then also by the immediate.
    int32_t out = 0; //Output
    out = (op << 26); //Shifts it padding it with the opcode
    out |= (rs << 21); //Fills it with next section RS, shifts again
    out |= (rd << 16); //Adds destination register
    out |= immediate; //Superpose with the immediate constant
    return out; //Returns the complete binary sequence
}
/*uint32_t Construct_J_Type(int op, int immediate) {
    //J type instruction declaration is the easiest variant, all parameters are just the opcode and the immediate addr
    int32_t out = 0; 
    out = (op << 26); //Shifts it 26 bits
    out |= immediate;
    return out; //Returns the complete binary sequence
}*/



int main() {
    int optest, rstest, rttest, rdtest, shamtttest, fctest;
    cout << bitset<32>(Construct_R_Type(0, 7, 8, 9, 0, 33)) << endl; //bitset is used to output uint32's as binary sequences
    cout << bitset<32>(Construct_I_Type(9, 7, 8, 16)) << endl;
}