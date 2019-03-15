#!/bin/bash

## This script is used to quality filter and trim poly g tails. It can process both paired end and single end data. 
BAMLIST=$1 # Path to a list of prefixes of the merged bam files. An example of such a sample list is /workdir/cod/greenland-cod/sample_lists/bam_list_1.tsv
BASEDIR=$2 # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "adapter_clipped" and into which output files will be written to separate subdirectories. An example for the Greenland cod data is: /workdir/cod/greenland-cod
REFNAME=$3 # Reference name to add to output files, e.g. gadMor2
# BAMTABLE=$4 # Path to a sample table where the 1st column is the prefix of the merged bam files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. The last column is the data type. An example of such a sample table is: /workdir/cod/greenland-cod/sample_lists/sample_table_merged.tsv

## Loop over each sample
for SAMPLEBAM in `cat $BAMLIST`; do

#### REMOVE DUPLICATES AND PRINT DUPSTAT FILE ####
# We used to be able to just specify picard.jar on the CBSU server, but now we need to specify the path and version

java -Xmx60g -jar /programs/picard-tools-2.9.0/picard.jar MarkDuplicates I=$BASEDIR'bam/'$SAMPLEBAM'_bt2_'$REFNAME'_MinQ20_sorted.bam' O=$BASEDIR'bam/'$SAMPLEBAM'_bt2_'$REFNAME'_MinQ20_sorted_dedup.bam' M=$BASEDIR'bam/'$SAMPLEBAM'_bt2_'$REFNAME'_MinQ20_sorted_dupstat.txt' VALIDATION_STRINGENCY=SILENT REMOVE_DUPLICATES=true

done
