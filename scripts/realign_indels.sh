#!/bin/bash

## This script is used to quality filter and trim poly g tails. It can process both paired end and single end data. 
BAMLIST=$1 # Path to a list of merged, deduplicated, and overlap clipped bam files. Full paths should be included. An example of such a bam list is /workdir/cod/greenland-cod/sample_lists/bam_list_1.tsv
BASEDIR=$2 # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "adapter_clipped" and into which output files will be written to separate subdirectories. An example for the Greenland cod data is: /workdir/cod/greenland-cod/
REFERENCE=$3 # Path to reference fasta file and file name, e.g /workdir/cod/reference_seqs/gadMor2.fasta
SAMTOOLS=${4:-samtools} # Path to samtools
JAVA=${5:-/usr/local/jdk1.8.0_121} # Path to java
GATK=${6:-/programs/GenomeAnalysisTK-3.7/GenomeAnalysisTK.jar} # Path to GATK
JOBS=${7:-1} # Number of indexing jobs to run in parallel (default 1)

JOB_INDEX=0

## Loop over each sample
for SAMPLEBAM in `cat $BAMLIST`; do

if [ -e $SAMPLEBAM'.bai' ]; then
	echo "the file already exists"
else
	## Index bam files
	$SAMTOOLS index $SAMPLEBAM &

	JOB_INDEX=$(( JOB_INDEX + 1 ))
	if [ $JOB_INDEX == $JOBS ]; then
		wait
		JOB_INDEX=0
	fi
fi

done

## Realign around in-dels
# This is done across all samples at once

## Use an older version of Java
export JAVA_HOME=$JAVA
export PATH=$JAVA_HOME/bin:$PATH

## Create list of potential in-dels
if [ ! -f $BASEDIR'bam/all_samples_for_indel_realigner.intervals' ]; then
	java -Xmx40g -jar $GATK \
	   -T RealignerTargetCreator \
	   -R $REFERENCE \
	   -I $BAMLIST \
	   -o $BASEDIR'bam/all_samples_for_indel_realigner.intervals' \
	   -drf BadMate
fi

## Run the indel realigner tool
java -Xmx40g -jar $GATK \
   -T IndelRealigner \
   -R $REFERENCE \
   -I $BAMLIST \
   -targetIntervals $BASEDIR'bam/all_samples_for_indel_realigner.intervals' \
   --consensusDeterminationModel USE_READS  \
   --nWayOut _realigned.bam
