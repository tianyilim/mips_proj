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

    if "comment" in line:
        continue
    if line == '':
        continue

    tmp.write(line+'\n')

tmp.close()
f.close()