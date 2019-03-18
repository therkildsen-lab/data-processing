#!/bin/bash

# This script is used to detect the species compsition of adaptor clipped sequences in fastq.gz format. It is intended for pair end reads.

SAMPLELIST=$1 # Path to a list of prefixes of the raw fastq files. It should be a subset of the the 1st column of the sample table. An example of such a sample list is /workdir/cod/greenland-cod/sample_lists/sample_list_pe_1.tsv
SAMPLETABLE=$2 # Path to a sample table where the 1st column is the prefix of the raw fastq files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. The 6th column should be data type, which is either pe or se. An example of such a sample table is: /workdir/cod/greenland-cod/sample_lists/sample_table.tsv
FASTQDIR=$3 # Path to the directory where fastq file are stored. An example for the quality-filtered Greenland data is: /workdir/cod/greenland-cod/qual_filtered/
FASTQSUFFIX1=$4 # Suffix to fastq files. Use forward reads with paired-end data. An example for the quality-filtered Greenland paired-end data is: _adapter_clipped_qual_filtered_f_paired.fastq.gz
FASTQSUFFIX2=$5 # Suffix to fastq files. Use reverse reads with paired-end data. An example for the quality-filtered Greenland paired-end data is: _adapter_clipped_qual_filtered_r_paired.fastq.gz
SAMPREADS=$6 # Number of reads to sample per fastq file, e.g. 2000
ECUT=$7 # E-value cut off, e.g. "1e-20"

##### RUN EACH SAMPLE THROUGH PIPELINE #######

# Loop over each sample
for SAMPLEFILE in `cat $SAMPLELIST`; do

# Extract relevant values from a table of sample and sequencing ID (here in columns 3 and 4, respectively) for each sequenced library
SAMPLE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 4`
SEQ_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 3`
LANE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 2`
SAMPLE_SEQ_ID=$SAMPLE_ID'_'$SEQ_ID'_'$LANE_ID  # When a sample has been sequenced in multiple lanes, we need to be able to identify the files from each run uniquely

SAMPLETOBLAST=$FASTQDIR$SAMPLE_SEQ_ID  # The input path and file base name

## Extract data type from the sample table
DATATYPE=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 6`

## Run fastq_species_detector.sh
if [ $DATATYPE = pe ]; then
bash /workdir/data-processing/scripts/fastq_species_detector.sh  $SAMPLETOBLAST$FASTQSUFFIX1  /workdir/my_db $SAMPREADS $ECUT
bash /workdir/data-processing/scripts/fastq_species_detector.sh  $SAMPLETOBLAST$FASTQSUFFIX2  /workdir/my_db $SAMPREADS $ECUT

else [ $DATATYPE = se ]
bash /workdir/data-processing/scripts/fastq_species_detector.sh  $SAMPLETOBLAST$FASTQSUFFIX1  /workdir/my_db $SAMPREADS $ECUT
fi

done