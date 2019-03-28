#!/bin/awk

## This script is used to convert a count matrix to a presense/absense matrix (1/0). 
# You should use the "-v" option in awk to define the variable "column_to_start", which is the column index of the first column that contains the count data.
BEGIN { OFS = FS = " " }
NR != 0 {
    for (i = column_to_start; i <= NF; ++i) { # Change the index of this loop as needed
        if ($i != "0") {
            $i = "1";
        }
    }
}

{ print }
