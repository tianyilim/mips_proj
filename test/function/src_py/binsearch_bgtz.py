import random
def binarySearch (arr, l, r, x): 
    # Check base case 
    if r >= l: 
        mid = l + (r - l) // 2
        # If element is present at the middle itself 
        if arr[mid] == x: 
            return mid 
        # If element is smaller than mid, then it  
        # can only be present in left subarray 
        elif arr[mid] > x: 
            return binarySearch(arr, l, mid-1, x) 
        # Else the element can only be present  
        # in right subarray 
        else: 
            return binarySearch(arr, mid + 1, r, x) 
    else: 
        # Element is not present in the array 
        return -1

# Ensures that list is sorted
test = range(1,20)
for i in test:
    x = [0]
    for n in range(100):
        x.append( random.randint(x[-1]+1,x[-1]+2) )
    find = random.randint(x[0], x[-1])
    # x = [0,1,2,3,4,5,6,7,8,9,10,11]
    # find = i

    # print(x, find)
    # print( find, binarySearch(x, 0, len(x), find) )

    writeFile = "test/function/src_bin/binsearch_bgtz_%d.data.hex" %(i)
    wf = open(writeFile, 'w')
    # print(writeFile, "<-", i) # Debug output

    expectedOutput = "test/function/expected_output/binsearch_bgtz_%d.txt" %(i)
    af = open(expectedOutput, 'w')

    ans = binarySearch(x, 0, len(x), find)
    if ans==-1:
        ansStr = "FFFFFFFF"
    else:
        ansStr = "%08x" %( ans << 2 )
    # print(expectedOutput, "<-", ans)

    # wf.write(format(i, 'x'))
    wf.write("%08x\n" %(find))
    wf.write("0000000C\n")
    arrEnd = 0xC + len(x)*4
    wf.write("%08x\n" %(arrEnd))
    for m in x:
        wf.write("%08x\n" %m) # 
    af.write(ansStr)

    af.close()
    wf.close()