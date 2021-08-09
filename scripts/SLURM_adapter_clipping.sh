#!/bin/bash -l
#SBATCH --job-name=SLURM_adapter_clipping
#SBATCH --output=SLURM_adapter_clipping_out.txt

########## REQUIREMENTS ########## 

# Use the --export=VARIABLE_NAME=VALUE command to pass in these variables (the order doesn't matter):
# 1. SERVER: the server to mount (ex: cbsunt246 or cbsubscb16)
# 2. BASEDIR: path to the base directory on the mounted server where adapter clipped fastq file are to be stored in a subdirectory titled "adapter_clipped" (ex: /workdir/cod/greenland-cod/). This is the same as the 4th argument provided to the adapter_clipping.sh script.
# 3. SAMPLELIST: path to a list of prefixes of the raw fastq files on the mounted server. This should be a subset of the the 1st column of the sample table (ex: /workdir/cod/greenland-cod/sample_lists/sample_list_pe_1.tsv). This is the same as the 1st argument provided to the adapter_clipping.sh script.
# 4. SAMPLETABLE: path to a sample table on the mounted server (ex: /workdir/cod/greenland-cod/sample_lists/sample_table.tsv), where the 1st column is the prefix of the raw fastq files, the 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. The 6th column should be data type, which is either pe or se. This is the same as the 2nd argument provided to the adapter_clipping.sh script.
# 5. RAWFASTQDIR: path to raw fastq files on the mounted server (ex: /workdir/backup/cod/greenland_cod/fastq/). This is the same as the 3rd argument to the adapter_clipping.sh script
# 6. RAWFASTQSUFFIX1: suffix to raw fastq files. Use forward reads with paired-end data (ex: _R1.fastq.gz). This is the same as the 5th argument provided to the adapter_clipping.sh script.
# 7. RAWFASTQSUFFIX2: suffix to raw fastq files. Use reverse reads with paired-end data (ex: _R2.fastq.gz). This is the same as the 6th argument provided to the adapter_clipping.sh script.
# 8. ADAPTERS: path to a list of adapter/index sequences on the mounted server. (ex: for Nextera libraries, /workdir/cod/reference_seqs/NexteraPE_NT.fa and for BEST libraries, /workdir/cod/reference_seqs/BEST.fa). This is the same as the 7th argument provided to the adapter_clipping.sh script.
# 9. TRIMMOMATIC: path to trimmomatic (default: /programs/trimmomatic/trimmomatic-0.39.jar). This is the same as the 8th argument provided to the adapter_clipping.sh script.
# 10. THREADS: number of threads to use / number of "tasks" per array job (ex: 8). This is the same as the 9th argument provided to the adapter_clipping.sh script.
# 11. ARRAY_LENGTH: the number of array jobs to divide adapter clipping into. This must be less than or equal to the total number of samples in the SAMPLELIST. The number of samples that will be processed by each array job is equal to floor(total number of samples / ARRAY_LENGTH), and the memory and partition headers should be based on this.

# Use the --array command to specify the array length, which must be the same as the ARRAY_LENGTH variable passed through --export
# --array=1-$ARRAY_LENGTH

# Use the --ntasks command to specify the number of threads per array job. This must be the same as the THREADS variable passed through --export
# --ntasks=$THREADS

# Use the --mem command to specify the maximum memory to be allocated to each array job. This will depend on the number of samples processed per array job (at least floor(total sample size/ARRAY_LENGTH))
# ex: --mem=3G

# Use the --partition command to specify the queue for each array job. This must be one of: short (max 4 hrs), regular (max 24 hrs), long7 (max 7 days), long30 (max 30 days), or gpu (max 3 days). This will depend on the number of samples processed in each array job (at least floor(total sample size/ARRAY_LENGTH))
# ex: --partition=short

#####################################

# Create and move to working directory for job
BASEWORKDIR=/workdir/$USER/$SLURM_JOB_ID-$SLURM_ARRAY_TASK_ID/
WORKDIR=${BASEWORKDIR}adapter_clipped/
mkdir -p $WORKDIR
cd $WORKDIR

# If the server is cbsunt246, this will be /workdir. If the server is cbsubscb16, this will be /storage
ROOTDIR=/`echo $BASEDIR | awk -F "/" '{print $2}'`
/programs/bin/labutils/mount_server $SERVER $ROOTDIR

# These are all small files that will only be read once. Therefore, we won't copy them over, but we will modify the path to these mounted files.
PREFIX=/fs/$SERVER
SAMPLE_LIST_SLURM=$PREFIX$SAMPLELIST
SAMPLE_TABLE_SLURM=$PREFIX$SAMPLETABLE
ADAPTER_LIST_SLURM=$PREFIX$ADAPTERS
SCRIPT=$PREFIX$ROOTDIR/data-processing/scripts/adapter_clipping.sh
BASEWORKDIR=/workdir/$USER/$SLURM_JOB_ID-$SLURM_ARRAY_TASK_ID/

# If the total number of samples in the SAMPLELIST is not a multiple of ARRAY_LENGTH, then the last array job will loop over a greater number of samples to reach the end of the SAMPLELIST.
TOTAL_NUMBER_OF_SAMPLES=`grep -c ".*" $SAMPLE_LIST_SLURM`
NUMBER_OF_SAMPLES_IN_EACH_ARRAY=$((TOTAL_NUMBER_OF_SAMPLES/ARRAY_LENGTH))

# The samples that this array job is responsible for:
LINE_START=$((1 + (SLURM_ARRAY_TASK_ID-1)*(NUMBER_OF_SAMPLES_IN_EACH_ARRAY)))
LINE_END=$((LINE_START+NUMBER_OF_SAMPLES_IN_EACH_ARRAY-1))

if [[ $SLURM_ARRAY_TASK_ID -eq $ARRAY_LENGTH ]]; then
  LINE_END=$TOTAL_NUMBER_OF_SAMPLES
fi

TEMPORARY_SAMPLE_LIST=$SLURM_ARRAY_TASK_ID.txt
awk "NR >= $LINE_START && NR <= $LINE_END" $SAMPLE_LIST_SLURM > $TEMPORARY_SAMPLE_LIST

# Copy the fastq files into this working directory
for SAMPLEFILE in `cat $TEMPORARY_SAMPLE_LIST`; do
  RAWFASTQ_ID=$PREFIX$RAWFASTQDIR$SAMPLEFILE
  cp $RAWFASTQ_ID$RAWFASTQSUFFIX1 .
  cp $RAWFASTQ_ID$RAWFASTQSUFFIX2 .
done

# Call the adapter_clipping.sh script, which will loop over only the samples specified by this array job.
bash $SCRIPT $TEMPORARY_SAMPLE_LIST $SAMPLE_TABLE_SLURM $WORKDIR $BASEWORKDIR $RAWFASTQSUFFIX1 $RAWFASTQSUFFIX2 $ADAPTER_LIST_SLURM $TRIMMOMATIC $THREADS

# Copy all output files back to the base directory on the mounted server
cp *adapter_clipped*.fastq.gz $PREFIX$BASEDIR'adapter_clipped/'

# Remove this working directory
rm -rf $WORKDIR
