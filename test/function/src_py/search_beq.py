import random
def search(n,x):
    for i in range(0,len(x)):
        if n == x[i]:
            return i
    return 10

test = range(1,8)

for i in test:
    x = [0,0,0,0,0,3]
    for n in range(0,5):
        x[n] = random.randint(1,20)


    writeFile = "test/function/src_bin/search_beq_%d.data.hex" %(i)
    wf = open(writeFile, 'w')
    # print(writeFile, "<-", i) # Debug output

    expectedOutput = "test/function/expected_output/search_beq_%d.txt" %(i)
    af = open(expectedOutput, 'w')
    ans = search(i,x)
    ansStr = "%08x" %( ans )
    # print(expectedOutput, "<-", ans)

    wf.write(format(i, 'x'))
    for m in range(0,6):
        wf.write("\n%08x" %(x[m])) # 
    af.write(ansStr)

    af.close()
    wf.close()