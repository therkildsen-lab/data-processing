#!/bin/bash

## This script is used to clip adapters. It can process both paired end and single end data. 
SAMPLELIST=$1 # Path to a list of prefixes of the raw fastq files. It should be a subset of the the 1st column of the sample table. An example of such a sample list is /workdir/cod/greenland-cod/sample_lists/sample_list_pe_1.tsv
SAMPLETABLE=$2 # Path to a sample table where the 1st column is the prefix of the raw fastq files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. The 6th column should be data type, which is either pe or se. An example of such a sample table is: /workdir/cod/greenland-cod/sample_lists/sample_table.tsv
RAWFASTQDIR=$3 # Path to raw fastq files. An example for the Greenland cod data is: /workdir/backup/cod/greenland_cod/fastq/
BASEDIR=$4 # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "adapter_clipped" and into which output files will be written to separate subdirectories. An example for the Greenland cod data is: /workdir/cod/greenland-cod/
RAWFASTQSUFFIX1=$5 # Suffix to raw fastq files. Use forward reads with paired-end data. An example for the Greenland paired-end data is: _R1.fastq.gz
RAWFASTQSUFFIX2=$6 # Suffix to raw fastq files. Use reverse reads with paired-end data. An example for the Greenland paired-end data is: _R2.fastq.gz
ADAPTERS=$7 # Path to a list of adapter/index sequences. For Nextera libraries: /workdir/cod/reference_seqs/NexteraPE_NT.fa For BEST libraries: /workdir/cod/reference_seqs/BEST.fa


## Loop over each sample
for SAMPLEFILE in `cat $SAMPLELIST`; do

## Extract relevant values from a table of sample, sequencing, and lane ID (here in columns 4, 3, 2, respectively) for each sequenced library
SAMPLE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 4`
SEQ_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 3`
LANE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 2`
SAMPLE_SEQ_ID=$SAMPLE_ID'_'$SEQ_ID'_'$LANE_ID  # When a sample has been sequenced in multiple lanes, we need to be able to identify the files from each run uniquely

## Extract data type from the sample table
DATATYPE=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 6`

## The input and output path and file prefix
RAWFASTQ_ID=$RAWFASTQDIR$SAMPLEFILE
SAMPLEADAPT=$BASEDIR'adapter_clipped/'$SAMPLE_SEQ_ID

## Adapter clip the reads with Trimmomatic
# The options for ILLUMINACLIP are: ILLUMINACLIP:<fastaWithAdaptersEtc>:<seed mismatches>:<palindrome clip threshold>:<simple clip threshold>:<minAdapterLength>:<keepBothReads>
# For definitions of these options, see http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/TrimmomaticManual_V0.32.pdf
if [ $DATATYPE = pe ]; then
java -jar /programs/trimmomatic/trimmomatic-0.39.jar PE -threads 18 -phred33 $RAWFASTQ_ID$RAWFASTQSUFFIX1 $RAWFASTQ_ID$RAWFASTQSUFFIX2 $SAMPLEADAPT'_adapter_clipped_f_paired.fastq.gz' $SAMPLEADAPT'_adapter_clipped_f_unpaired.fastq.gz' $SAMPLEADAPT'_adapter_clipped_r_paired.fastq.gz' $SAMPLEADAPT'_adapter_clipped_r_unpaired.fastq.gz' 'ILLUMINACLIP:'$ADAPTERS':2:30:10:1:true'

else [ $DATATYPE = se ]
java -jar /programs/trimmomatic/trimmomatic-0.39.jar SE -threads 18 -phred33 $RAWFASTQ_ID$RAWFASTQSUFFIX1 $SAMPLEADAPT'_adapter_clipped_se.fastq.gz' 'ILLUMINACLIP:'$ADAPTERS':2:30:10'
fi

done
