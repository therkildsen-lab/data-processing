#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --job-name=quality_filtering
#SBATCH --output=quality_filtering.log

########## REQUIREMENTS ########## 

# Use the --export=VARIABLE_NAME=VALUE command to pass in these variables (the order doesn't matter):
# 1. SERVER: the server and the directory to mount to the computing node (ex: 'cbsunt246 workdir/' or 'cbsubscb16 storage/')
# 2. BASEDIR: path to the base directory on the computing node (once mounting is complete) where adapter clipped fastq file are already stored in subdirectory titled "adapter_clipped/" and where the quality-filtered fastq files will be placed in a subdirectory titled "qual_filtered/" (ex: /fs/cbsunt246/workdir/cod/greenland-cod/). This is the same as the 3rd argument provided to the quality_filtering.sh script.
# 3. SAMPLELIST: path to a list of prefixes of the raw fastq files on the computing node once mounting is complete. This should be a subset of the the 1st column of the sample table (ex: /fs/cbsunt246/workdir/cod/greenland-cod/sample_lists/sample_list_pe_1.tsv). This is the same as the 1st argument provided to the quality_filtering.sh script.
# 4. SAMPLETABLE: path to a sample table on the computing node once mounting is complete (ex: /workdir/cod/greenland-cod/sample_lists/sample_table.tsv), where the 1st column is the prefix of the raw fastq files, the 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. The 6th column should be data type, which is either pe or se. This is the same as the 2nd argument provided to the quality_filtering.sh script.
# 5. FILTER: the type of quality filtering. One of: polyg (forced PolyG trimming only), quality (quality trimming, PolyG will be trimmed as well if processing NextSeq/NovaSeq data), or length (trim all reads to a maximum length). This is the same as the 4th argument provided to the quality_filtering.sh script.
# 6. MAXLENGTH: if FILTER=length, then this is required and represents the maximum length (ex: 100). This is the same as the 7th argument provided to the quality_filtering.sh script. If FILTER is not length, then this argument is not needed.
# 7. FASTP: the path to the fastp program that can be accessed from the SLURM cluster (default was /workdir/programs/fastp_0.19.7/fastp; to modify this to the mounted path, use /fs/cbsunt246/workdir/programs/fastp_0.19.7/fastp. The path to the fastp program installed on the SLURM cluster is /programs/fastp-0.20.0/bin/fastp). This is the same as the 6th argument provided to the quality_filtering.sh script.
# 8. THREADS: number of threads to use / number of "tasks" per array job (ex: 8). This is the same as the 5th argument provided to the quality_filtering.sh script.
# 9. ARRAY_LENGTH: the number of array jobs to divide adapter clipping into. This must be less than or equal to the total number of samples in the SAMPLELIST. The number of samples that will be processed by each array job is equal to floor(total number of samples / ARRAY_LENGTH), and the memory and partition headers should be based on this.
# 10. SCRIPT: path to the quality_filtering.sh script on the computing node once mounting is complete (ex: /fs/cbsunt246/workdir/data-processing/scripts/quality_filtering.sh)

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
mkdir -p $BASEWORKDIR
cd $BASEWORKDIR

# This requires an adapter_clipped/ subfolder for the input and a qual_filtered/ subfolder for the output
mkdir adapter_clipped
mkdir qual_filtered
ADAPTERCLIPPEDDIR=${BASEWORKDIR}adapter_clipped/
WORKDIR=${BASEWORKDIR}qual_filtered/
cd $WORKDIR

# If the server is cbsunt246, workdir/ should be mounted. If the server is cbsubscb16, storage/ should be mounted.
/programs/bin/labutils/mount_server $SERVER

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

# Copy the adapter-clipped fastq files into this working directory. The name and number of these files depends on the data in the sample table.
for SAMPLEFILE in `cat $TEMPORARY_SAMPLE_LIST`; do
  DATATYPE=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 6`
  SAMPLE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 4`
	SEQ_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 3`
	LANE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLETABLE | cut -f 2`
	SAMPLE_SEQ_ID=$SAMPLE_ID'_'$SEQ_ID'_'$LANE_ID
	SAMPLEADAPT=$BASEDIR'adapter_clipped/'$SAMPLE_SEQ_ID
  if [ $DATATYPE = pe ]; then
    cp $SAMPLEADAPT'_adapter_clipped_f_paired.fastq.gz' $ADAPTERCLIPPEDDIR
    cp $SAMPLEADAPT'_adapter_clipped_r_paired.fastq.gz' $ADAPTERCLIPPEDDIR
  elif [ $DATATYPE = se ]; then
    cp $SAMPLEADAPT'_adapter_clipped_se.fastq.gz' $ADAPTERCLIPPEDDIR
  fi
done

# Call the quality_filtering.sh script, which will loop over only the samples specified by this array job.
if [ $FILTER = length ]; then
  bash $SCRIPT $TEMPORARY_SAMPLE_LIST $SAMPLETABLE $BASEWORKDIR $FILTER $THREADS $FASTP $MAXLENGTH
else
  bash $SCRIPT $TEMPORARY_SAMPLE_LIST $SAMPLETABLE $BASEWORKDIR $FILTER $THREADS $FASTP
fi

# Copy all output files back to the base directory on the mounted server
cp * $BASEDIR'qual_filtered/'

# Remove this working directory and other subfolders
rm -rf $BASEWORKDIR
