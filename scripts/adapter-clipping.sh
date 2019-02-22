##### RUN EACH SAMPLE THROUGH PIPELINE #######



# Loop over each sample
for SAMPLEFILE in `cat $SAMPLELIST`; do

# Extract relevant values from a table of sample and sequencing ID (here in columns 3 and 4, respectively) for each sequenced library
SEQ_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLELIBRARYINFO | cut -f 3`
SAMPLE_ID=`grep -P "${SAMPLEFILE}\t" $SAMPLELIBRARYINFO | cut -f 4`

SAMPLE_SEQ_ID=$SAMPLE_ID'_'$SEQ_ID  # When a sample has been sequenced in multiple lanes, we need to be able to identify the files from each run uniquely

FASTQ=$BASEDIR'Fastq/'$SAMPLEFILE  # The input path and file prefix
SAMPLEADAPT=$BASEDIR'AdapterClipped/'$SAMPLE_SEQ_ID  # The output path and file prefix


#### CLEANING THE READS ####

# Remove adapter sequence with Trimmomatic. 
java -jar /programs/trimmomatic/trimmomatic-0.36.jar PE -threads 18 -phred33 $FASTQ'_R1.fastq.gz' $FASTQ'_R2.fastq.gz' $SAMPLEADAPT'_AdapterClipped_F_paired.fastq.gz' $SAMPLEADAPT'_AdapterClipped_F_unpaired.fastq.gz' $SAMPLEADAPT'_AdapterClipped_R_paired.fastq.gz' $SAMPLEADAPT'_AdapterClipped_R_unpaired.fastq.gz' 'ILLUMINACLIP:'$ADAPTERS':2:30:10:4:true'

done
