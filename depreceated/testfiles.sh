#!/bin/bash

INSTRUCTION="$1"




for (( i=1; i<=4; i++ ))
do

touch  ./0-assembly/incomplete/${INSTRUCTION}_$i.asm.txt
touch ./2-simulator/${INSTRUCTION}_$i.txt

done
