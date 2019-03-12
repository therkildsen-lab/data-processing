#!/bin/bash 

#export BLASTDB=/data/tst/contam_chk/db

if [ $# -lt 2 ]
then
	echo
	echo Prerequisites:
	echo "    BLAST+  (location of executables must be in the PATH)"
	echo "    nt databases (with taxonomy files taxdb.btd and taxdb.bti) in a local directory" 
	echo
	echo Usage:
	echo
	echo "$0 FASTQ_FILE  PATH_TO_NT_DATABASE [E_CUT]"
	echo
	echo where:
	echo 
	echo "FASTQ_FILE is the fastq file, gzipped or not, to be analyzed"
	echo "           (no line breaks allowed within sequence)"
	echo
	echo "PATH_TO_NT_DATABASE is the full path to the local directory containing the NCBI nt"
	echo "                    database (files nt.*) and the taxonomy files taxdb.btd and taxdb.bti"
	echo
	echo "ECUT is the maximum BLAST e-value for significant hit detection (default: 1e-20)"
	echo
	echo Output will be written to file called FASTQ_FILE.species_stats
	echo
	exit
fi

FASTQ=$1
BLASTDB=$2
export BLASTDB
SAMPREADS=$3
ECUT=$4

SCRIPTDIR=`dirname "$BASH_SOURCE"`

echo Subsampling fastq
/workdir/data-processing/scripts/subsample_fastq.pl $FASTQ $SAMPREADS fasta >& $FASTQ.tst.fa

echo Runing BLAST
#blastn -num_threads 5 -db $BLASTDB/nt -query $FASTQ.tst.fa -out $FASTQ.blast  -outfmt "6 std staxids sscinames scomnames sblastnames"
blastn -db $BLASTDB/nt -query $FASTQ.tst.fa -out $FASTQ.blast  -outfmt "6 std staxids sscinames scomnames sblastnames"
sort -k 1,1 -k 12,12nr $FASTQ.blast > $FASTQ.blast.sorted
mv $FASTQ.blast.sorted $FASTQ.blast

echo Counting reads
echo Species detected in file $FASTQ > $FASTQ.species_stats
echo based on $SAMPREADS uniformly sampled reads >> $FASTQ.species_stats
/workdir/data-processing/scripts/count_species.pl $FASTQ.blast $ECUT >> $FASTQ.species_stats 2>&1
