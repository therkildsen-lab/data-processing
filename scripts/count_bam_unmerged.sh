#!/bin/bash

SAMPLETABLE=$1 # This is actually the sample table!

printf 'SampleID\tMappedBases\tQualFiltMappedBases\n'
for LINE in `cat $SAMPLETABLE | cut -f1`; do

SAMPLEFILE='/workdir/Backup/WhiteSturgeon/Fastq/'$LINE'_1.txt.gz'

SAMPLE=`grep "^${LINE}" $SAMPLETABLE | cut -f4`
SEQID=`grep "^${LINE}" $SAMPLETABLE | cut -f2`

RAWBAMFILE='/workdir/Sturgeon/BamFiles/'$SAMPLE'_'$SEQID'_Paired_bt2_AciTrans1.bam'
MAPPEDBASES=`samtools view $RAWBAMFILE | cut -f 10 | wc | awk '{printf $3-$1}'`
QUALFILTBAMFILE='/workdir/Sturgeon/BamFiles/'$SAMPLE'_'$SEQID'_Paired_bt2_AciTrans1_MinQ20_sorted.bam'
QUAFILTBASES=`samtools view $QUALFILTBAMFILE | cut -f 10 | wc | awk '{printf $3-$1}'`

printf "%s\t%s\t%s\n" $SAMPLE $MAPPEDBASES $QUAFILTBASES

done

# nohup bash /workdir/Sturgeon/ShellScripts/GetUnmergedMappedReadCounts.sh /workdir/Backup/WhiteSturgeon/SampleLists/SampleTable.txt >& /workdir/Sturgeon/ShellScripts/GetUnmergedMappedReadCounts.nohup &
