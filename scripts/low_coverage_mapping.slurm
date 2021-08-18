#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --job-name=low_coverage_mapping
#SBATCH --output=low_coverage_mapping.log

########## REQUIREMENTS ########## 

# Use the --export=VARIABLE_NAME=VALUE command to pass in these variables (the order doesn't matter):
# 01. SERVER: the server and the directory to mount to the computing node (ex: 'cbsunt246 workdir/' or 'cbsubscb16 storage/')
# 02. BASEDIR: path to the base directory on the computing node (once mounting is complete) where bam files will be stored in subdirectory titled "bam/" (ex: /fs/cbsunt246/workdir/cod/greenland-cod/).
# 03. FASTQDIR: path to the base directory on the computing node (once mounting is complete) where fastq files ready for mapping are stored (ex: /fs/cbsunt246/workdir/cod/greenland-cod/qual_filtered).
# 04. SAMPLELIST: path to a list of prefixes of the raw fastq files on the computing node once mounting is complete. This should be a subset of the the 1st column of the sample table (ex: /fs/cbsunt246/workdir/cod/greenland-cod/sample_lists/sample_list_pe_1.tsv). This is the same as the 1st argument provided to the low_coverage_mapping.sh script.
# 05. SAMPLETABLE: path to a sample table on the computing node once mounting is complete (ex: /fs/cbsunt246/workdir/cod/greenland-cod/sample_lists/sample_table.tsv), where the 1st column is the prefix of the raw fastq files, the 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. The 6th column should be data type, which is either pe or se. This is the same as the 2nd argument provided to the low_coverage_mapping.sh script.
# 06. FASTQSUFFIX1: Suffix to fastq files. Use forward reads with paired-end data. An example for the quality-filtered Greenland paired-end data is: _adapter_clipped_qual_filtered_f_paired.fastq.gz
# 07. FASTQSUFFIX2: Suffix to fastq files. Use reverse reads with paired-end data. An example for the quality-filtered Greenland paired-end data is: _adapter_clipped_qual_filtered_r_paired.fastq.gz
# 08. MAPPINGPRESET: The pre-set option to use for mapping in bowtie2 (very-sensitive for end-to-end (global) mapping [typically used when we have a full genome reference], very-sensitive-local for partial read mapping that allows soft-clipping [typically used when mapping genomic reads to a transcriptome]
# 09. REFERENCE: Path to reference fasta file and file name on the computing node, e.g /fs/cbsunt246/workdir/cod/reference_seqs/gadMor2.fasta
# 10. REFNAME: Reference name to add to output files, e.g. gadMor2
# 11. MINQ: Minimum mapping quality filter (ex: 0, which means no filter will be applied).
# 12. BOWTIE: the path to the bowtie2 program that can be accessed from the SLURM cluster (ex: bowtie2, which will use the system default bowtie2).
# 13. SAMTOOLS: the path to the samtools program that can be accessed from the SLURM cluster (ex: samtools, which will use the system default samtools).
# 14. THREADS: the number of threads to use / number of "tasks" per array job (ex: 8). This is the same as the 10th argument provided to the low_coverage_mapping.sh script.
# 15. ARRAY_LENGTH: the number of array jobs to divide adapter clipping into. This must be less than or equal to the total number of samples in the SAMPLELIST. The number of samples that will be processed by each array job is equal to floor(total number of samples / ARRAY_LENGTH), and the memory and partition headers should be based on this.
# 16. SCRIPT: path to the low_coverage_mapping.sh script on the computing node once mounting is complete (ex: /fs/cbsunt246/workdir/data-processing/scripts/low_coverage_mapping.sh)

# Use the --array command to specify the array length, which must be the same as the ARRAY_LENGTH variable passed through --export
# --array=1-$ARRAY_LENGTH

# Use the --ntasks command to specify the number of threads per array job. This must be the same as the THREADS variable passed through --export
# --ntasks=$THREADS

# Use the --mem command to specify the maximum memory to be allocated to each array job. This will depend on the number of samples processed per array job (at least floor(total sample size/ARRAY_LENGTH))
# ex: --mem=3G

# Use the --partition command to specify the queue for each array job. This must be one of: short (max 4 hrs), regular (max 24 hrs), long7 (max 7 days), long30 (max 30 days), or gpu (max 3 days). This will depend on the number of samples processed in each array job (at least floor(total sample size/ARRAY_LENGTH))
# ex: --partition=short

#####################################

# Keep a record of the Job ID
echo $SLURM_JOB_ID

# Create and move to working directory for job
WORKDIR=/workdir/$USER/$SLURM_JOB_ID-$SLURM_ARRAY_TASK_ID/
mkdir -p $WORKDIR
cd $WORKDIR

# This requires an adapter_clipped/ subfolder for the input and a qual_filtered/ subfolder for the output
mkdir fastq
mkdir bam
mkdir reference
INPUTDIR=$WORKDIR'fastq/'

# If the server is cbsunt246, workdir/ should be mounted. If the server is cbsubscb16, storage/ should be mounted.
/programs/bin/labutils/mount_server $SERVER

# Copy the reference sequence and indices to the computing node
REFBASENAME="${REFERENCE%%.*}"
cp ${REFBASENAME}'.*' $WORKDIR'reference/'

# The following operation is used to divide the sample list as evenly among array jobs as possible.
TOTAL_NUMBER_OF_SAMPLES=`grep -c ".*" $SAMPLELIST`
QUOTIENT=$((TOTAL_NUMBER_OF_SAMPLES/ARRAY_LENGTH))
REMAINDER=$((TOTAL_NUMBER_OF_SAMPLES%ARRAY_LENGTH))
if [[ $SLURM_ARRAY_TASK_ID -le $REMAINDER ]]; then
  NUMBER_OF_SAMPLES_IN_EACH_ARRAY=$((QUOTIENT+1))
  LINE_START=$((1 + (SLURM_ARRAY_TASK_ID-1)*(NUMBER_OF_SAMPLES_IN_EACH_ARRAY)))
else
  NUMBER_OF_SAMPLES_IN_EACH_ARRAY=$QUOTIENT
  LINE_START=$((1 + (SLURM_ARRAY_TASK_ID-1)*(NUMBER_OF_SAMPLES_IN_EACH_ARRAY) + REMAINDER))
fi
LINE_END=$((LINE_START+NUMBER_OF_SAMPLES_IN_EACH_ARRAY-1))

# The samples that this array job is responsible for:
TEMPORARY_SAMPLE_LIST=$SLURM_ARRAY_TASK_ID.txt
awk "NR >= $LINE_START && NR <= $LINE_END" $SAMPLELIST > $TEMPORARY_SAMPLE_LIST

# Copy the ready-for-mapping fastq files into this working directory. The name and number of these files depends on the data in the sample table.
for SAMPLEFILE in `cat $TEMPORARY_SAMPLE_LIST`; do
  DATATYPE=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 6`
  SAMPLE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 4`
	SEQ_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 3`
	LANE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 2`
	SAMPLE_SEQ_ID=$SAMPLE_ID'_'$SEQ_ID'_'$LANE_ID

  if [ $DATATYPE = pe ]; then
    cp $FASTQDIR'/'$SAMPLE_SEQ_ID$FASTQSUFFIX1 $INPUTDIR
    cp $FASTQDIR'/'$SAMPLE_SEQ_ID$FASTQSUFFIX2 $INPUTDIR
  elif [ $DATATYPE = se ]; then
    cp $FASTQDIR'/'$SAMPLE_SEQ_ID$FASTQSUFFIX1 $INPUTDIR
  fi
done

# Call the low_coverage_mapping.sh script, which will loop over only the samples specified by this array job.
bash $SCRIPT $TEMPORARY_SAMPLE_LIST $SAMPLETABLE $INPUTDIR $WORKDIR $FASTQSUFFIX1 $FASTQSUFFIX2 $MAPPINGPRESET $WORKDIR'reference/'${REFBASENAME##*/} $REFNAME $THREADS $MINQ $BOWTIE $SAMTOOLS

# Copy all output files back to the base directory on the mounted server
cp ${WORKDIR}/bam/*bam $BASEDIR'bam/'

# Remove this working directory and other subfolders
rm -rf $WORKDIR
