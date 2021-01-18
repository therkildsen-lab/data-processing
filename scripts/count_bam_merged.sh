#!/bin/bash

# This script is used to count bam files after merging. These include deduplication and overlap clipping (paired-end data only)
BAMLIST=$1 # Path to a list of merged bam files. Full paths should be included. An example of such a bam list is /workdir/cod/greenland-cod/sample_lists/bam_list_merged.tsv
SAMPLETABLE=$2 # Path to a sample table where the 1st column is the prefix of the MERGED bam files. The 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The 5th column is population name and 6th column is the data type. An example of such a sample table is: /workdir/cod/greenland-cod/sample_lists/sample_table_merged.tsv
BASEDIR=$3 # Path to the base directory where adapter clipped fastq file are stored in a subdirectory titled "adapter_clipped" and into which output files will be written to separate subdirectories. An example for the Greenland cod data is: /workdir/cod/greenland-cod/
REFNAME=$4 # Reference name to add to output files, e.g. gadMor2
MINMAPQ=$5 # Minimum mapping quality filter (can be blank, in which case the filtered won't be applied)

if [ ! -z "$MINMAPQ" ]; then
	printf 'sample_id\tdedup_mapped_bases\tavg_fragment_size\toverlap_clipped_bases\tminmapq'$MINQ'_bases\n'
else
	printf 'sample_id\tdedup_mapped_bases\tavg_fragment_size\toverlap_clipped_bases\n'
fi

for SAMPLEBAM in `cat $BAMLIST`; do
	
	## Extract the file name prefix for this sample
	SAMPLEPREFIX=`echo $SAMPLEBAM | sed 's/_bt2_.*//' | sed -e 's#.*/bam/\(\)#\1#'`
	
	## Count deduplicated bases
	DEDUPFILE=$BASEDIR'bam/'$SAMPLEPREFIX'_bt2_'$REFNAME'_minq20_sorted_dedup.bam'
	DEDUPMAPPEDBASES=`samtools stats $DEDUPFILE -@ 4 | grep ^SN | cut -f 2- | grep "^bases mapped (cigar)" | cut -f 2`
	
	## Extract data type from the merged sample table
	DATATYPE=`grep -P "${SAMPLEPREFIX}\t" $SAMPLETABLE | cut -f 6`
	
	if [ $DATATYPE != se ]; then
		## Calculate average fragment length for paired end reads
		AVGFRAG=`samtools view $DEDUPFILE | grep YT:Z:CP | awk '{sum+=sqrt($9^2)} END {printf "%f", sum/NR}'`
		if [ "$AVGFRAG" == '' ]; then AVGFRAG=0 ; fi
	
		## Count overlap clipped bam files for paired end reads 
		CLIPOVERLAPFILE=$BASEDIR'bam/'$SAMPLEPREFIX'_bt2_'$REFNAME'_minq20_sorted_dedup_overlapclipped.bam'
		CLIPOVERLAPBASES=`samtools stats $CLIPOVERLAPFILE -@ 4 | grep ^SN | cut -f 2- | grep "^bases mapped (cigar)" | cut -f 2`
		
		if [ ! -z "$MINMAPQ" ]; then
			MINMAPQBASES=`samtools view -q $MINMAPQ $CLIPOVERLAPFILE -@ 4 | samtools stats -@ 4| grep ^SN | cut -f 2- | grep "^bases mapped (cigar)" | cut -f 2`
		fi
	else
		AVGFRAG=NA
		CLIPOVERLAPBASES=NA
		if [ ! -z "$MINMAPQ" ]; then
			MINMAPQBASES=`samtools view -q $MINMAPQ $DEDUPFILE -@ 4 | samtools stats -@ 4| grep ^SN | cut -f 2- | grep "^bases mapped (cigar)" | cut -f 2`
		fi
	fi
	
	if [ ! -z "$MINMAPQ" ]; then
		printf "%s\t%s\t%s\t%s\n" $SAMPLEPREFIX $DEDUPMAPPEDBASES $AVGFRAG $CLIPOVERLAPBASES $MINMAPQBASES
	else
		printf "%s\t%s\t%s\t%s\n" $SAMPLEPREFIX $DEDUPMAPPEDBASES $AVGFRAG $CLIPOVERLAPBASES
	fi

	
	
done
