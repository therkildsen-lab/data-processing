#!/bin/awk

## This script is used to sum up a matrix by rows. 
# You should use the "-v" option in awk to define the variable "column_to_start", which is the column index of the first column that you want to start summing from.
BEGIN { OFS = FS = " " }
NR != 0 {
    for (i = column_to_start; i <= NF; i++) t+=$i; print t; t=0
}