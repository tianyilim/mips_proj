# Test for the Fibonacci sequence
def fib(n):
    if n<2:
        return n
    return fib(n-1) + fib(n-2)

test = [0,1,3,5,7,9,11]
# test = range(6)
# for i in test:
#     print(i,fib(i))

for i in test:
    writeFile = "test/function/src_bin/fib_jal_%d.data.hex" %(i)
    wf = open(writeFile, 'w')
    # print(writeFile, "<-", i) # Debug output

    expectedOutput = "test/function/expected_output/fib_jal_%d.txt" %(i)
    af = open(expectedOutput, 'w')
    ans = fib(i)
    ansStr = "%08x" %( ans )
    # print(expectedOutput, "<-", ans)

    wf.write(format(i, 'x'))
    wf.write("\nFFFFFFFF") # 
    af.write(ansStr)

    af.close()
    wf.close()