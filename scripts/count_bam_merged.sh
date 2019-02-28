#!/bin/bash

SAMPLETABLE=$1 # This is actually the sample table!

printf 'SampleID\tDedupMappedBases\tAvgFragmentSize\tOverlapClippedBases\n'
for LINE in `cat $SAMPLETABLE | cut -f1`; do

DEDUPFILE='/workdir/Sturgeon/BamFiles/'$LINE'_Paired_bt2_AciTrans1_MinQ20_sorted_merged_dedup.bam'
DEDUPMAPPEDBASES=`samtools view $DEDUPFILE | cut -f 10 | wc | awk '{printf $3-$1}'`
AVGFRAG=`samtools view $DEDUPFILE | awk '{sum+=sqrt($9^2)} END {printf "%f", sum/NR}'`

CLIPOVERLAPFILE='/workdir/Sturgeon/BamFiles/'$LINE'_Paired_bt2_AciTrans1_MinQ20_sorted_merged_dedup_clipOverlap.bam'
CLIPOVERLAPBASES=`samtools stats $CLIPOVERLAPFILE | grep ^SN | cut -f 2- | grep "^bases mapped (cigar)" | cut -f 2`

printf "%s\t%s\t%s\t%s\n" $LINE $DEDUPMAPPEDBASES $AVGFRAG $CLIPOVERLAPBASES

done

# nohup bash /workdir/Sturgeon/ShellScripts/GetMergedMappedReadCounts.sh /workdir/Sturgeon/SampleLists/SampleTable_merged.txt >& /workdir/Sturgeon/ShellScripts/MergedMappedReadCounts.nohup &
