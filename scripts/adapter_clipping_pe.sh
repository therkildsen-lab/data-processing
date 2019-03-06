#!/bin/bash

## This script is used to clip adapters
SAMPLELIST=$1 # Path to a list of prefixes of the raw fastq files. It can be a subset of the the 1st column of the sample table.
SAMPLETABLE=$2 # Path to a sample table where the 1st column is the prefix of the raw fastq files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. An example of such a sample table is: /workdir/Backup/WhiteSturgeon/SampleLists/SampleTable.txt
RAWFASTQDIR=$3 # Path to raw fastq files. An example for the sturgeon data is: /workdir/Backup/WhiteSturgeon/Fastq/
BASEDIR=$4 # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "AdapterClipped" and into which output files will be written to separate subdirectories. An example for the sturgeon data is: /workdir/Sturgeon/
RAWFASTQSUFFIX1=$5 # Suffix to forward raw fastq files. An example for the sturgeon data is: _1.txt.gz
RAWFASTQSUFFIX2=$6 # Suffix to reverse raw fastq files. An example for the sturgeon data is: _2.txt.gz
ADAPTERS=$7 # Path to a list of adapter/index sequences. For Nextera libraries: /workdir/Cod/ReferenceSeqs/NexteraPE_NT.fa For BEST libraries: /workdir/Cod/ReferenceSeqs/BEST.fa

##### RUN EACH SAMPLE THROUGH PIPELINE #######

# Loop over each sample
for SAMPLEFILE in `cat $SAMPLELIST`; do

# Extract relevant values from a table of sample, sequencing, and lane ID (here in columns 4, 3, 2, respectively) for each sequenced library
SAMPLE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 4`
SEQ_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 3`
LANE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 2`

SAMPLE_SEQ_ID=$SAMPLE_ID'_'$SEQ_ID'_'$LANE_ID  # When a sample has been sequenced in multiple lanes, we need to be able to identify the files from each run uniquely

FASTQ=$RAWFASTQDIR$SAMPLEFILE  # The input path and file prefix
SAMPLEADAPT=$BASEDIR'AdapterClipped/'$SAMPLE_SEQ_ID  # The output path and file prefix

#### ADAPTER CLIPPING THE READS ####

# Remove adapter sequence with Trimmomatic. 
# The options for ILLUMINACLIP are: ILLUMINACLIP:<fastaWithAdaptersEtc>:<seed mismatches>:<palindrome clip threshold>:<simple clip threshold>:<minAdapterLength>:<keepBothReads>
# For definitions of these options, see http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/TrimmomaticManual_V0.32.pdf
java -jar /programs/trimmomatic/trimmomatic-0.36.jar PE -threads 18 -phred33 $FASTQ$RAWFASTQSUFFIX1 $FASTQ$RAWFASTQSUFFIX2 $SAMPLEADAPT'_AdapterClipped_F_paired.fastq.gz' $SAMPLEADAPT'_AdapterClipped_F_unpaired.fastq.gz' $SAMPLEADAPT'_AdapterClipped_R_paired.fastq.gz' $SAMPLEADAPT'_AdapterClipped_R_unpaired.fastq.gz' 'ILLUMINACLIP:'$ADAPTERS':2:30:10:1:true'

done
