from sys import argv
import os

assert(len(argv) > 1)
for filename in argv[1:]:
    f = open(filename,"r")

    testname = os.path.splitext(filename)[0]    # get rid of extension
    testname = testname.split('/')[-1]          # get rid of /
    testname = testname.split('.')[0]           # get rid of trailing intermediate
    # print(testname)

    section={}
    curr_sect = -1
    for line in f:
        if line[0]=='.':
            line=line.strip()
            section[line[1:]]=[]
            curr_sect = line[1:]
        else:
            section[curr_sect].append(line)

    print(section)

    dataFile = open("test/1-binary/%s.data.hex" %(testname), 'w')
    for line in section['data']:
        dataFile.write(line)
    dataFile.close()

    instrFile = open("test/1-binary/%s.instr.hex" %(testname), 'w')
    for line in section['instr']:
        instrFile.write(line)
    instrFile.close()

    outFile = open("test/2-simulator/%s.txt" %(testname), 'w')
    for line in section['output']:
        outFile.write(line)
    outFile.close()

    debugFile = open("test/4-reference/%s.txt" %(testname), 'w')
    for line in section['debug']:
        debugFile.write(line)
    debugFile.close()

    f.close()