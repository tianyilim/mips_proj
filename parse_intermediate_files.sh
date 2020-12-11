#!/bin/bash
for FILENAME in test/1-binary/*.intermediate.txt; do
    [ -e "$FILENAME" ] || continue # Avoid case where there are no matches
    python3 test/parse_intermediates.py $FILENAME
done