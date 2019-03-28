BEGIN { OFS = FS = " " }

NR != 0 {
    for (i = column_to_start; i <= NF; i++) t+=$i; print t; t=0
}