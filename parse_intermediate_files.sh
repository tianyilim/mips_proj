#!/bin/bash
for FILENAME in test/1-binary/*.intermediate.txt; do
    python3 test/parse_intermediates.py $FILENAME
done