# Test for Factorial numbers
from math import factorial

test = [0,1,3,5,7,9,13,15,17]

for i in test:
    writeFile = "test/function/src_bin/fact_mflo_%d.data.hex" %(i)
    wf = open(writeFile, 'w')
    # print(writeFile, "<-", hex(i)) # Debug output

    expectedOutput = "test/function/expected_output/fact_mflo_%d.txt" %(i)
    af = open(expectedOutput, 'w')
    ans = factorial(i)
    if (ans>>32):
        # Don't give any file if it is out of bound
        # continue
        ansStr = "FFFFFFFF" # Error code
    else:
        ansStr = "%08x" %( ans ) # 32-bit mask

    wf.write(format(i, 'x'))
    wf.write("\nFFFFFFFF") # 
    af.write(ansStr)

    af.close()
    wf.close()