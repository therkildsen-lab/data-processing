BEGIN { OFS = FS = " " }

NR != 0 {
    for(i=1;i<=NF;i++) t+=$i; print t; t=0
}

#{ print }