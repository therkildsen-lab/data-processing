#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --job-name=deduplicate_clipoverlap
#SBATCH --output=deduplicate_clipoverlap.log

########## REQUIREMENTS ########## 

# Use the --export=VARIABLE_NAME=VALUE command to pass in these variables (the order doesn't matter):
# 01. SERVER: the server and the directory to mount to the computing node (ex: 'cbsunt246 workdir/' or 'cbsubscb16 storage/')
# 02. BAMLIST: path to a list of merged bam files on the computing node once mounting is complete (ex: /fs/cbsunt246/workdir/cod/greenland-cod/sample_lists/bam_list_merged.txt)
# 03. SAMPLETABLE: path to a sample table on the computing node once mounting is complete (ex: /fs/cbsunt246/workdir/cod/greenland-cod/sample_lists/sample_table.tsv), where the 1st column is the prefix of the raw fastq files, the 4th column is the sample ID, the 2nd column is the lane number, and the 3rd column is sequence ID. The combination of these three columns have to be unique. The 6th column should be data type, which is either pe or se. This is the same as the 2nd argument provided to the low_coverage_mapping.sh script.
# 04. JAVA: the path to java that can be accessed from the SLURM cluster (ex: java, which will use the system default java).
# 05. PICARD: the path to the picard program that can be accessed from the SLURM cluster (ex: /programs/picard-tools-2.9.0/picard.jar).
# 06. BAMUTIL: the path the the bamutil program that can be accessed from the SLUMR cluster (ex: /programs/bamUtil/bam)
# 07. ARRAY_LENGTH: the number of array jobs to divide adapter clipping into. This must be less than or equal to the total number of samples in the BAMLIST. The number of samples that will be processed by each array job is equal to floor(total number of samples / ARRAY_LENGTH), and the memory and partition headers should be based on this.
# 08. SCRIPT: path to the deduplicate_clipoverlap.sh script on the computing node once mounting is complete (ex: /fs/cbsunt246/workdir/data-processing/scripts/deduplicate_clipoverlap.sh)

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

# This requires an bam/ subfolder for the input and output bam files
mkdir bam
BAMDIR_LOCAL=$WORKDIR'bam/'

# If the server is cbsunt246, workdir/ should be mounted. If the server is cbsubscb16, storage/ should be mounted.
/programs/bin/labutils/mount_server $SERVER

# Extract the path where the input bam files are stored (we assume that all input bam files are stored in the same location)

BAMDIR_MOUNTED=`head $BAMLIST -n 1 | sed 's|\(.*\)/.*|\1|'`/

# The following operation is used to divide the sample list as evenly among array jobs as possible.
TOTAL_NUMBER_OF_SAMPLES=`grep -c ".*" $BAMLIST`
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
TEMPORARY_BAM_LIST_LOCAL=$SLURM_ARRAY_TASK_ID.local.txt
TEMPORARY_BAM_LIST_MOUNTED=$SLURM_ARRAY_TASK_ID.mounted.txt

awk "NR >= $LINE_START && NR <= $LINE_END" $BAMLIST > $TEMPORARY_BAM_LIST_MOUNTED
sed 's+'$BAMDIR_MOUNTED'+'$BAMDIR_LOCAL'+g' $TEMPORARY_BAM_LIST_MOUNTED > $TEMPORARY_BAM_LIST_LOCAL


# Copy the bam files into this working directory. The name and number of these files depends on the data in the sample table.
for LINE in `cat $TEMPORARY_BAM_LIST_MOUNTED`; do
  cp $LINE $BAMDIR_LOCAL
done


# Call the deduplicate_clipoverlap.sh script, which will loop over only the samples specified by this array job.
bash $SCRIPT $TEMPORARY_BAM_LIST_LOCAL $SAMPLETABLE $JAVA $PICARD $BAMUTIL

# Copy all output files back to the base directory on the mounted server
cp ${BAMDIR_LOCAL}/*_dedup* $BAMDIR_MOUNTED
cp ${BAMDIR_LOCAL}/*_dupstat.txt $BAMDIR_MOUNTED

# Remove this working directory and other subfolders
rm -rf $WORKDIR
