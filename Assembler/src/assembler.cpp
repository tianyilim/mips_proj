#include <iostream>
#include <cmath>
#include <string>
#include <vector>
#include <algorithm>
#include <map>
#include <bitset>
#include <fstream>
#include <cstring>
#include <string.h>
#include <stdlib.h>
//Sry for the include spam, was experimenting a lot.

using namespace std;

map<string, uint32_t> Registers = {
    {"$zero", 0},
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
};

/*Initially I wanted to implement the macro definition of the registers just like Justin did on his C test script, but I couldn't get this to work with my wider function so
for simplification, I implemented registers as a HashMap, it just maps the strings to their associated integers.
*/


/* Below are some of the helper functions I'll be declaring, the first 3 are the most crucial, the R, I and J type instructions. I also have functions to convert the
null terminated character arrays parsed from text into the strings, and then mapping them to register ints, and also a helper function to convert immediates into the required form.
They take mostly the same kinda form, and it's simple to explain.
*/

vector<bitset<32> >instructions; //Used bitset<32>, pretty strange choice of library but I found this easier than implementing a separate num->bin converter function, and more efficient.
//All this does is basically store 32 bit binary sequences as elements in a vector, everytime we go through a line, and call one of the R,I, or J functions, a 32 bit number is added to this vector.

/* R type instructions: Take in an instruction type, and operate based on 3 registers mostly (Except for shifts), 
i.e addu $0, $1, $2 adds values in R[1] and R[2], stored in R[0].
*/

void Construct_R_Type(int op, int rs, int rt, int rd, int shamt, int fc) { //First generator function, takes in 6 params which we know from the Excel (Thanks CH!! I wouldn't have had the patience to painstakingly find each instruction and then implement it :')) )
    bitset<32> out = 0; //32 bit output instantiated
    out = (op << 26); //Opcode superposed in first 6 bits
    out |= (rs << 21); //Register in next 5 bits
    out |= (rt << 16); //Next register
    out |= (rd << 11); //Destination register
    out |= (shamt << 6); //Superposes shift amount, if any
    out |= fc; //Ends with fc which is already 0 by default, our R type requirement. //
    instructions.push_back(out); //Returns the complete binary sequence into the vector of processed instructions.
}

void Construct_I_Type(int op, int rs, int rt, int immediate) {
    //For the I type instruction, I have to shift by the opcode just like before, shift rs and rd, but then also by the immediate.
    bitset<32> out = 0; //Output same as before
    out = (op << 26); 
    out |= (rs << 21); 
    out |= (rt << 16); 
    out |= immediate; //Superpose with the immediate constant
    out |= (immediate & 65535); //ERR checking, to be refined later on.
    instructions.push_back(out); //Returns the complete binary sequence
}

void Construct_J_Type(int op, int immediate) {
    //J type instruction declaration is the easiest variant, all parameters are just the opcode and the immediate addr
    bitset<32> out = 0; 
    out = (op << 26); //Superpose opcode, same as before
    out |= immediate; //Remaining 26 bits are the required parts.
    instructions.push_back(out); //Returns the complete binary sequence
}


int RegisterToInteger(char* Register) { //As you will later see, we parse each line by returning 4 tokens, form char *, to be able to operate with them we gotta convert them to integers
    return Registers[string(Register)]; //Cast the char array to a string, and then use that new string as the key in our hashmap to find the associated int.
}


int ConvertImmediate(char *immediate){ //As before, we have tokens for each part of the instruction, including the immediate, we gotta convert this into a useable form.
    // 3 cases - hexadecimal and decimal immediate, the EXTRA case is the case of zero offset, i.e offset is given as $zero
    if(strcmp(immediate, "$zero") == 0) {
        return Registers[immediate];
    }
    char *hexcase;
    hexcase = strstr(immediate, "0x"); //Checks for occurence of Hex in the constant, we can use this for a case by case consideration
    if (hexcase != NULL) { //Case 1: If the ptr isn't null then it means that we have an occurence of Hex in the constant.
        return (int)strtol(immediate, NULL, 16); //We use strtol as an easy way of converting it into the actual number, we cast it to int.
    } else { //Case 2: The ptr is the nullptr and that means we have no 0x and no hex immediate, we can just return the number as it is.
        return atoi(immediate);
    }
}

//Helper functions made, next step is to read the files directly. 






//Ignore the random stuff in between, just random ramblings and thoughts I never really got round to implementing, to be cleaned up later.








/*
int itype(int opcode, int rt, int rs, int imm)
{
	int x = 0;
	imm = (imm & 0xffff);
	rt = (rt & 0x1f) << 16;
	rs = (rs & 0x1f) << 21;
	opcode = (opcode & 0x3f) << 26;
	x |= imm;
	x |= rt;
	x |= rs;
	x |= opcode;
	return x;
}
*/

//Need to account for case when immediate is in Hex.





int main() {
    /*
    int optest, rstest, rttest, rdtest, shamtttest, fctest;
    cout << bitset<32>(Construct_R_Type(0, 7, 8, 9, 0, 33)) << endl; //bitset is used to output uint32's as binary sequences
    cout << bitset<32>(Construct_I_Type(9, 7, 8, 16)) << endl;
    cout << $ra << endl;
    */


   //The below system opens the test file, we assume it to be txt for now but I will change this to asm if unavoidable.
   string line;
   ifstream parsedfile("test.txt");
   if (parsedfile.is_open()) {
       while(getline(parsedfile,line)) {
           char delims[] = " (),\t"; //These are the standard delimiters in a MIPs file, we can split these into tokens.
           char linearr[20]; //Char array, because I can use the C string operations on them
           line.copy(linearr, line.size() + 1); //Copies the line from the .txt string, casts it into the array
           char * firstparam; //Four tokens we need to parse the individual parts
           char * secondparam;
           char * thirdparam;
           char * fourthparam = NULL; //These are the four parameters of the instruction, the instruction type, the registers involved (2 for some and 3 for others), where a third instruction isn't used we have an immediate constant
               
           firstparam = strtok(linearr, delims); //Generate the tokens we need
           if(firstparam != NULL) 
                secondparam = strtok(NULL,delims); //This splits it into four, whenever we hit a delimiter we call the function again.
           if(secondparam != NULL)
                thirdparam = strtok(NULL,delims);
           if(thirdparam != NULL)
                fourthparam = strtok(NULL,delims);
           //I have managed to split the text up now for each given line. I need to split this into a separate function, so that we can handle each string/line individually.

            /*Implementation of the various I-Type instruction, depending on the instruction, we will use the general I-type constructor to generate
            the specific instructions, if the first token is equal to a given operation, we construct the binary instruction taking in the appropriate parameters,
            we use the other tokens to do this, opcode is just the int number, and we use the RegToInt functions in order to generate the registers needed, ConvertImmediate
            takes in the value of the constant, whether that be Hexadecimal or a standard Integer, every call adds a new instruction to the vector<bitset<32> > instructions.
            */
            if (strcmp(firstparam, "addiu") == 0) {
                Construct_I_Type(9, RegisterToInteger(thirdparam), RegisterToInteger(secondparam), ConvertImmediate(fourthparam));
            } //All I did for literally every instruction was refer to our Excel document, and fill in the gaps, the rest follows
            if (strcmp(firstparam, "andi") == 0) {
                Construct_I_Type(12, RegisterToInteger(thirdparam), RegisterToInteger(secondparam), ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "beq") == 0) {
                Construct_I_Type(4, RegisterToInteger(thirdparam), RegisterToInteger(secondparam), ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "bgez") == 0) {
                Construct_I_Type(1, RegisterToInteger(thirdparam), 1, ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "bgezal") == 0) {
                Construct_I_Type(1, RegisterToInteger(thirdparam), 17, ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "bgtz") == 0) {
                Construct_I_Type(7, RegisterToInteger(thirdparam), 0, ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "blez") == 0) {
                Construct_I_Type(6, RegisterToInteger(thirdparam), 0, ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "bltz") == 0) {
                Construct_I_Type(1, RegisterToInteger(thirdparam), 0, ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "bltzal") == 0) {
                Construct_I_Type(1, RegisterToInteger(thirdparam), 16, ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "bne") == 0) {
                Construct_I_Type(5, RegisterToInteger(thirdparam), RegisterToInteger(secondparam), ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "lb") == 0) {
                Construct_I_Type(32, RegisterToInteger(fourthparam), RegisterToInteger(secondparam), ConvertImmediate(thirdparam));
            }
            if (strcmp(firstparam, "lbu") == 0) {
                Construct_I_Type(36, RegisterToInteger(fourthparam), RegisterToInteger(secondparam), ConvertImmediate(thirdparam));
            }
            if (strcmp(firstparam, "lh") == 0) {
                Construct_I_Type(33, RegisterToInteger(fourthparam), RegisterToInteger(secondparam), ConvertImmediate(thirdparam));
            }
            if (strcmp(firstparam, "lhu") == 0) {
                Construct_I_Type(37, RegisterToInteger(fourthparam), RegisterToInteger(secondparam), ConvertImmediate(thirdparam));
            }
            if (strcmp(firstparam, "lui") == 0) {
                Construct_I_Type(15, 0, RegisterToInteger(secondparam), ConvertImmediate(fourthparam));
            } //Uhhh
            if (strcmp(firstparam, "lw") == 0) {
                //lw $rt, offset($rs)
                //This means that we have offset as third param,
                Construct_I_Type(35, RegisterToInteger(fourthparam), RegisterToInteger(secondparam), ConvertImmediate(thirdparam));
            }
            if (strcmp(firstparam, "lwl") == 0) {
                Construct_I_Type(34, RegisterToInteger(fourthparam), RegisterToInteger(secondparam), ConvertImmediate(thirdparam));
            }
            if (strcmp(firstparam, "lwr") == 0) {
                Construct_I_Type(42, RegisterToInteger(fourthparam), RegisterToInteger(secondparam), ConvertImmediate(thirdparam));
            }
            if (strcmp(firstparam, "ori") == 0) {
                Construct_I_Type(13, RegisterToInteger(thirdparam), RegisterToInteger(secondparam), ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "sb") == 0) {
                Construct_I_Type(40, RegisterToInteger(fourthparam), RegisterToInteger(secondparam), ConvertImmediate(thirdparam));
            }
            if (strcmp(firstparam, "sh") == 0) {
                Construct_I_Type(41, RegisterToInteger(fourthparam), RegisterToInteger(secondparam), ConvertImmediate(thirdparam));
            }
            if (strcmp(firstparam, "slti") == 0) {
                Construct_I_Type(10, RegisterToInteger(thirdparam), RegisterToInteger(secondparam), ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "sltiu") == 0) {
                Construct_I_Type(11, 0, RegisterToInteger(secondparam), ConvertImmediate(fourthparam));
            }
            if (strcmp(firstparam, "sw") == 0) {
                Construct_I_Type(43, RegisterToInteger(fourthparam), RegisterToInteger(secondparam), ConvertImmediate(thirdparam));
            }
            if (strcmp(firstparam, "xori") == 0) {
                Construct_I_Type(14, RegisterToInteger(thirdparam), RegisterToInteger(secondparam), ConvertImmediate(fourthparam));
            }

            /*
                I will now do the R-Type instructions, which are called in virtually the same way however will now use the R-Constructor, which takes in 
                extra parameters, now the Immediate (4th param) will just be called in as the 3rd register, and we will include other pre-defined values, the
                SHIFT AMT, and also the function code.
                Thankfully, for R-Type instructions most of these constants are pre-defined, the 3 exceptions are SRL, SRA, and SLL which we can just re-purpose the fourth param
                for, as the opcode is all 0 for the R-Type anyway.
            */

           if (strcmp(firstparam, "addu") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 33);
           }
           if (strcmp(firstparam, "and") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 36);
           }
           if (strcmp(firstparam, "div") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), 0, 0, 26);
           }
           if (strcmp(firstparam, "divu") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), 0, 0, 27);
           }
           if (strcmp(firstparam, "jalr") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 9);
           }
           if (strcmp(firstparam, "jr") == 0) {
               Construct_R_Type(0, RegisterToInteger(secondparam), 0, 0, 0, 8);
           } //jr only takes in two parameters, error was that we were pointing to nothing
           if (strcmp(firstparam, "mthi") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), 0, 0, 0, 17);
           }
           if (strcmp(firstparam, "mtlo") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), 0, 0, 0, 19);
           }
           if (strcmp(firstparam, "mult") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), 0, 0, 24);
           }
           if (strcmp(firstparam, "multu") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), 0, 0, 25);
           }
           if (strcmp(firstparam, "or") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 37);
           }
           if (strcmp(firstparam, "sll") == 0) {
               Construct_R_Type(0, 0, RegisterToInteger(thirdparam), RegisterToInteger(secondparam), ConvertImmediate(fourthparam), 0);
           } //SLL must be handled differently to other R types
           if (strcmp(firstparam, "sllv") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 4);
           }
           if (strcmp(firstparam, "slt") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 42);
           }
           if (strcmp(firstparam, "sltu") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 43);
           }
           if (strcmp(firstparam, "sra") == 0) {
               Construct_R_Type(0, 0, RegisterToInteger(thirdparam), RegisterToInteger(secondparam), ConvertImmediate(fourthparam), 3);
           }
           if (strcmp(firstparam, "srav") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 7);
           }
           if (strcmp(firstparam, "srl") == 0) {
               Construct_R_Type(0, 0, RegisterToInteger(thirdparam), RegisterToInteger(secondparam), ConvertImmediate(fourthparam), 2);
           }
           if (strcmp(firstparam, "srlv") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 6);
           }
           if (strcmp(firstparam, "subu") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 35);
           }
           if (strcmp(firstparam, "xor") == 0) {
               Construct_R_Type(0, RegisterToInteger(thirdparam), RegisterToInteger(fourthparam), RegisterToInteger(secondparam), 0, 38);
           }
           if (strcmp(firstparam, "mfhi") == 0) {
               Construct_R_Type(0, 0, 0, RegisterToInteger(secondparam), 0, 16);
           }
           if (strcmp(firstparam, "mflo") == 0) {
               Construct_R_Type(0, 0, 0, RegisterToInteger(secondparam), 0, 18);
           }

           /*
                The R type instructions are complete.
                Left to implement are 2 J type instructions. J and JAL, these are simple and merely only require 
                2 variables to read in too, so this can be done quickly. 
           */

            if (strcmp(firstparam, "j") == 0) {
                Construct_J_Type(2, (ConvertImmediate(secondparam) >> 2));
            }
            if (strcmp(firstparam, "jal") == 0) {
                Construct_J_Type(3, (ConvertImmediate(secondparam) >> 2));
            }

            //I still need to play around with the J type instructions to ensure they do the right thing.
        for(int i = 0; i<instructions.size();i++) {
            cout << hex << instructions[i].to_ulong() << endl;
        } //Just a test thing, I'll remove this later on
        
    }


}
    ofstream outFile("output.txt"); //Destination file
    for (const auto &e : instructions) outFile << hex << e.to_ulong() << "\n"; //Cast the elements of the array instructions onto the output file
    //EDIT: Changed radix of output file, keeps binary data structure just incase but outputs file in Hex
}