BEGIN { OFS = FS = " " }

NR != 0 {
    for (i = column_to_start; i <= NF; ++i) { # Change the index of this loop as needed
        if ($i != "0") {
            $i = "1";
        }
    }
}

{ print }
