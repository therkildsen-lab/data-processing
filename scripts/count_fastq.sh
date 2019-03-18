#!/bin/bash

## This script is used to count number of bases in raw, adapter clipped, and quality filtered fastq files. The result of this script will be stored in a nohup file.

SAMPLELIST=$1 # Path to a list of prefixes of the raw fastq files. It should be a subset of the the 1st column of the sample table. An example of such a sample list is /workdir/cod/greenland-cod/sample_lists/sample_list_pe_1.tsv
SAMPLETABLE=$2 # Path to a sample table where the 1st column is the prefix of the raw fastq files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. The 6th column should be data type, which is either pe or se. An example of such a sample table is: /workdir/cod/greenland-cod/sample_lists/sample_table.tsv
RAWFASTQDIR=$3 # Path to raw fastq files. An example for the Greenland cod data is: /workdir/backup/cod/greenland_cod/fastq/
BASEDIR=$4 # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "adapter_clipped" and into which output files will be written to separate subdirectories. An example for the Greenland cod data is: /workdir/cod/greenland-cod
SEQUENCER=$5 # Sequencer name that appears in the beginning of the first line in a fastq file. An example for the sturgeon data is: @HISEQ550
QUALFILTERED=$6 # Whether the sample has gone through quality filtering. true or false

# Create headers for the output
if $QUALFILTERED; then
printf 'sample_seq_id\traw_reads\traw_bases\tadapter_clipped_bases\tqual_filtered_bases\n'
else
printf 'sample_seq_id\traw_reads\traw_bases\tadapter_clipped_bases\n'
fi

# Loop over each sample in the sample table
for SAMPLEFILE in `cat $SAMPLELIST`; do
RAWFASTQFILES=$RAWFASTQDIR$SAMPLEFILE'*.gz'  # The input path and file prefix

# Count the number of reads in raw fastq files. We only need to count the forward reads, since the reverse will contain exactly the same number of reads. fastq files contain 4 lines per read, so the number of total reads will be half of this line number. 
RAWREADS=`zcat $RAWFASTQFILES | wc -l`

# Count the number of bases in raw fastq files. We only need to count the forward reads, since the reverse will contain exactly the same number of bases. The total number of reads will be twice this count. 
RAWBASES=`zcat $RAWFASTQFILES | grep -A 1 -E "^$SEQUENCER" | grep "^[ACGTN]" | tr -d "\n" | wc -m` 

# Extract relevant values from a table of sample, sequencing, and lane ID (here in columns 4, 3, 2, respectively) for each sequenced library
SAMPLE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 4`
SEQ_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 3`
LANE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 2`
SAMPLE_SEQ_ID=$SAMPLE_ID'_'$SEQ_ID'_'$LANE_ID

# Find all adapter clipped fastq files corresponding to this sample and store them in the object ADAPTERFILES.
ADAPTERFILES=$BASEDIR'adapter_clipped/'$SAMPLE_SEQ_ID'*.gz'

# Count all bases in adapter clipped files. 
ADPTERCLIPBASES=`zcat $ADAPTERFILES | grep -A 1 -E "^$SEQUENCER" | grep "^[ACGTN]" | tr -d "\n" | wc -m`

# If reads are quality filtered, count quality filtered files.
if $QUALFILTERED; then

# Find all quality trimmed fastq files corresponding to this sample and store them in the object QUALFILES.
QUALFILES=$BASEDIR'qual_filtered/'$SAMPLE_SEQ_ID'*.gz'

# Count bases in quality trimmed files.
QUALFILTPBASES=`zcat $QUALFILES | grep -A 1 -E "^$SEQUENCER" | grep "^[ACGTN]" | tr -d "\n" | wc -m`

# Write the counts in appropriate order.
printf "%s\t%s\t%s\t%s\t%s\n" $SAMPLE_SEQ_ID $((RAWREADS/4)) $RAWBASES $ADPTERCLIPBASES $QUALFILTPBASES

# When reads are not quality filtered, directly write the output
else 

# Write the counts in appropriate order.
printf "%s\t%s\t%s\t%s\n" $SAMPLE_SEQ_ID $((RAWREADS/4)) $RAWBASES $ADPTERCLIPBASES

fi

done
