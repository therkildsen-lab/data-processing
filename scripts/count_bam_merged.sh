#!/bin/bash

# This script is used to count bam files after merging. These include deduplication and overlap clipping (paired-end data only)
BAMLIST=$1 # Path to a list of merged bam files. Full paths should be included. An example of such a bam list is /workdir/cod/greenland-cod/sample_lists/bam_list_merged.tsv
SAMPLETABLE=$2 # Path to a sample table where the 1st column is the prefix of the MERGED bam files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The 5th column is population name and 6th column is the data type. An example of such a sample table is: /workdir/cod/greenland-cod/sample_lists/sample_table_merged.tsv
SAMTOOLS=${3:-samtools} # Path to samtools
MINMAPQ=${4-0} # Minimum mapping quality filter (the default is 0, in which case the filter won't be applied)
THREADS=${5-1} # Number of parallel threads to use. Default is 1.

if [ $MINMAPQ != 0 ]; then
	printf 'sample_id\tdedup_mapped_bases\tavg_fragment_size\toverlap_clipped_bases\tminmapq'$MINMAPQ'_bases\n'
else
	printf 'sample_id\tdedup_mapped_bases\tavg_fragment_size\toverlap_clipped_bases\n'
fi

for SAMPLEBAM in `cat $BAMLIST`; do
	
	## Extract the file name prefix for this sample
	SAMPLESEQID=`echo $SAMPLEBAM | sed 's/_bt2_.*//' | sed -e 's#.*/bam/\(\)#\1#'`
	SAMPLEPREFIX=`echo ${SAMPLEBAM%.bam}`
	
	## Count deduplicated bases
	DEDUPFILE=$SAMPLEPREFIX'_dedup.bam'
	DEDUPMAPPEDBASES=`$SAMTOOLS stats $DEDUPFILE -@ $THREADS | grep ^SN | cut -f 2- | grep "^bases mapped (cigar)" | cut -f 2`
	
	## Extract data type from the merged sample table
	DATATYPE=`grep -P "${SAMPLESEQID}\t" $SAMPLETABLE | cut -f 6`
	
	if [ $DATATYPE != se ]; then
		## Calculate average fragment length for paired end reads
		AVGFRAG=`$SAMTOOLS view -q $MINMAPQ $DEDUPFILE | grep YT:Z:CP | awk '{sum+=sqrt($9^2)} END {printf "%f", sum/NR}'`
		if [ "$AVGFRAG" == '' ]; then AVGFRAG=0 ; fi
	
		## Count overlap clipped bam files for paired end reads 
		CLIPOVERLAPFILE=$SAMPLEPREFIX'_dedup_overlapclipped.bam'
		CLIPOVERLAPBASES=`$SAMTOOLS stats $CLIPOVERLAPFILE -@ $THREADS | grep ^SN | cut -f 2- | grep "^bases mapped (cigar)" | cut -f 2`
		
		if [ $MINMAPQ != 0 ]; then
			MINMAPQBASES=`$SAMTOOLS view -h -q $MINMAPQ $CLIPOVERLAPFILE -@ $THREADS | $SAMTOOLS stats -@ $THREADS | grep ^SN | cut -f 2- | grep "^bases mapped (cigar)" | cut -f 2`
		fi
	else
		AVGFRAG=NA
		CLIPOVERLAPBASES=NA
		if [ $MINMAPQ != 0 ]; then
			MINMAPQBASES=`$SAMTOOLS view -h -q $MINMAPQ $DEDUPFILE -@ $THREADS | $SAMTOOLS stats -@ $THREADS | grep ^SN | cut -f 2- | grep "^bases mapped (cigar)" | cut -f 2`
		fi
	fi
	
	wait 

	if [ $MINMAPQ != 0 ]; then
		printf "%s\t%s\t%s\t%s\t%s\n" $SAMPLESEQID $DEDUPMAPPEDBASES $AVGFRAG $CLIPOVERLAPBASES $MINMAPQBASES
	else
		printf "%s\t%s\t%s\t%s\n" $SAMPLESEQID $DEDUPMAPPEDBASES $AVGFRAG $CLIPOVERLAPBASES
	fi

done
