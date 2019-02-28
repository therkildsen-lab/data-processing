#!/bin/bash

## This script is used to count number of bases in raw, adapter clipped, and quality filtered paired end fastq files. The result of this script will be stored in a nohup file.

SAMPLETABLE=$1 # Path to a sample table where the 1st column is the prefix of the raw fastq files. The 4th column is the sample ID and the 2nd column is the sequence ID or the lane number. The combination of these two columns have to be unique. An example of such a sample table is: /workdir/Backup/WhiteSturgeon/SampleLists/SampleTable.txt
RAWFASTQDIR=$2 # Path to raw fastq files. An example for the sturgeon data is: /workdir/Backup/WhiteSturgeon/Fastq/
BASEDIR=$3 # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "AdapterClipped" and into which output files will be written to separate subdirectories. An example for the sturgeon data is: /workdir/Sturgeon/
SEQUENCER=$4 # Sequencer name that appears in the beginning of the first line in a fastq file. An example for the sturgeon data is: @HISEQ550

# Create headers for the output
printf 'SampleID\tRawReads\tRawBases\tAdapterClippedBases\tQualFiltBases\n'

# Loop over each sample in the sample table
for LINE in `cat $SAMPLETABLE | cut -f1`; do
SAMPLEFILE=$RAWFASTQDIR$LINE'_1.txt.gz' # The suffix here might need to be modified. 

# Count the number of reads in raw fastq files. We only need to count the forward reads, since the reverse will contain exactly the same number of reads. fastq files contain 4 lines per read, so the number of total reads will be half of this line number. 
RAWREADS=`zcat $SAMPLEFILE | wc -l`

# Count the number of bases in raw fastq files. We only need to count the forward reads, since the reverse will contain exactly the same number of bases. The total number of reads will be twice this count. 
RAWBASES=`zcat $SAMPLEFILE | grep -A 1 -E $SEQUENCER | grep "^[ACGTN]" | tr -d "\n" | wc -m` 

# Find all adapter clipped fastq files corresponding to this sample and store them in the object ADAPTERFILES.
SAMPLE=`grep "^${LINE}" $SAMPLETABLE | cut -f4`
SEQID=`grep "^${LINE}" $SAMPLETABLE | cut -f2`
ADAPTERFILES=`ls $BASEDIR'AdapterClipped/' | grep "^${SAMPLE}_${SEQID}_"`

# To count all bases in adapter clipped files, we first merge all forward, reverse, paired, and unpaired fastq files. We then count the merged file, and delete it afterwards. 
for i in $ADAPTERFILES; do
cat $BASEDIR'AdapterClipped/'$i >> $BASEDIR'AdapterClipped/'$SAMPLE'_'$SEQUID'_merged.fastq'
done
ADPTERCLIPBASES=`grep -A 1 -E $SEQUENCER $BASEDIR'AdapterClipped/'$SAMPLE'_'$SEQUID'_merged.fastq' | grep "^[ACGTN]" | tr -d "\n" | wc -m`
rm $BASEDIR'AdapterClipped/'$SAMPLE'_'$SEQUID'_merged.fastq'

# Find all quality trimmed fastq files corresponding to this sample and store them in the object QUALFILES.
QUALFILES=`ls $BASEDIR'QualFilt/' | grep "^${SAMPLE}_${SEQID}_"`

# To count bases in quality trimmed files, we first merge all forward, reverse, paired, and unpared fastq files. We then count the merged file, and delete it afterwards. 
for i in $QUALFILES; do
cat $BASEDIR'QualFilt/'$i >>'$BASEDIR'QualFilt/'$SAMPLE'_'$SEQUID'_merged.fastq'
done
QUALFILTPBASES=`grep -A 1 -E $SEQUENCER $BASEDIR'QualFilt/'$SAMPLE'_'$SEQUID'_merged.fastq' | grep "^[ACGTN]" | tr -d "\n" | wc -m`
rm $BASEDIR'QualFilt/'$SAMPLE'_'$SEQUID'_merged.fastq'

# Write the counts in appropriate order.
printf "%s\t%s\t%s\t%s\t%s\n" $SAMPLE $((RAWREADS/2)) $((RAWBASES*2)) $ADPTERCLIPBASES $QUALFILTPBASES

done
