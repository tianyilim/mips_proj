from sys import argv
import os

# Extract file
assert(len(argv)==2)

# Read input file line by line
f = open(argv[1])
tmp = open("test/Assembler/src/test.txt", 'w')
for line in f:
    stuff = line.split('#') # Gets rid of comments
    line=stuff[0].strip()
    line=line.lower()       # ensure that comments are stringed
    if "comment" in line:
        break # Disregard everything after 'comment'

    if line == '':
        continue # Disregard empty lines

    if line=="nop":
        line="addiu $zero, $zero, 0"

    # Add trailing commas for assembler
    if line[-1] != ')' or line[-1] != ',':
        line += ','
    
    # print(line)

    tmp.write(line+'\n')

tmp.close()
f.close()