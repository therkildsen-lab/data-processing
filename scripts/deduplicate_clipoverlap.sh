#!/bin/bash

## This script is used to deduplicate bam files and clipped overlapping read pairs for paired end data. It can process both paired end and single end data.
BAMLIST=$1 # Path to a list of merged, deduplicated, and overlap clipped bam files. Full paths should be included. An example of such a bam list is /workdir/cod/greenland-cod/sample_lists/bam_list_1.tsv
SAMPLETABLE=$2 # Path to a sample table where the 1st column is the prefix of the MERGED bam files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The 5th column is population name and 6th column is the data type. An example of such a sample table is: /workdir/cod/greenland-cod/sample_lists/sample_table_merged.tsv
JAVA=${3:-java} # Path to java
PICARD=${4:-/programs/picard-tools-2.9.0/picard.jar} # Path to picard tools
BAMUTIL=${5:-/programs/bamUtil/bam} # Path to bamUtil


## Loop over each sample
for SAMPLEBAM in `cat $BAMLIST`; do
	
	## Extract the file name prefix for this sample
	SAMPLESEQID=`echo $SAMPLEBAM | sed 's/_bt2_.*//' | sed -e 's#.*/bam/\(\)#\1#'`
	SAMPLEPREFIX=`echo ${SAMPLEBAM%.bam}`

	## Remove duplicates and print dupstat file
	# We used to be able to just specify picard.jar on the CBSU server, but now we need to specify the path and version
	$JAVA -Xmx60g -jar $PICARD MarkDuplicates I=$SAMPLEBAM O=$SAMPLEPREFIX'_dedup.bam' M=$SAMPLEPREFIX'_dupstat.txt' VALIDATION_STRINGENCY=SILENT REMOVE_DUPLICATES=true
	
	## Extract data type from the merged sample table
	DATATYPE=`grep -P "${SAMPLESEQID}\t" $SAMPLETABLE | cut -f 6`
	
	if [ $DATATYPE != se ]; then
		## Clip overlapping paired end reads (only necessary for paired end data)
		$BAMUTIL clipOverlap --in $SAMPLEPREFIX'_dedup.bam' --out $SAMPLEPREFIX'_dedup_overlapclipped.bam' --stats
	fi
	
done
