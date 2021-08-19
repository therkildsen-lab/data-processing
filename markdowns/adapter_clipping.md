Adapter clipping
================

-   [Introduction](#introduction)
-   [Standalone server](#standalone-server)
-   [Computer cluster](#computer-cluster)
-   [Output](#output)
-   [Notes](#notes)

## Introduction

Adapter clipping is process that removes adapter read-throughs in
sequencing reads where the insert size is shorter than the read length.
It is a required step for our pipeline.

We use `Trimmomatic` to perform adapter clipping. Please make sure that
it is installed on your machine. In addition, a file with adapter
sequences is required. Below is an example adapter file for Nextera
libraries.

    >PrefixNX/1
    AGATGTGTATAAGAGACAG
    >PrefixNX/2
    AGATGTGTATAAGAGACAG
    >Trans1
    TCGTCGGCAGCGTCAGATGTGTATAAGAGACAG
    >Trans1_rc
    CTGTCTCTTATACACATCTGACGCTGCCGACGA
    >Trans2
    GTCTCGTGGGCTCGGAGATGTGTATAAGAGACAG
    >Trans2_rc
    CTGTCTCTTATACACATCTCCGAGCCCACGAGAC
    >Prefix_PCR/1
    AATGATACGGCGACCACCGAGATCTACAC
    >Prefix_PCR/2
    CAAGCAGAAGACGGCATACGAGAT
    >PCR_i5
    AATGATACGGCGACCACCGAGATCTACAC
    >PCR_i5_rc
    GTGTAGATCTCGGTGGTCGCCGTATCATT
    >PCR_i7
    CAAGCAGAAGACGGCATACGAGAT
    >PCR_i7_rc
    ATCTCGTATGCCGTCTTCTGCTTG

Because raw fastq files often have complex and non-standardized names,
we also take advantage of this step to standardize the naming of fastq
files downstream.

<br>

## Standalone server

Run the
[adapter\_clipping.sh](https://github.com/therkildsen-lab/data-processing/blob/master/scripts/adapter_clipping.sh)
script with `nohup bash` and pass the following input variables as
positional parameters **in the given order**:

1.  `SAMPLELIST`: Path to a list of prefixes of the raw fastq files. It
    should be a subset of the the 1st column of the sample table
    (e.g. `/workdir/cod/greenland-cod/sample_lists/sample_list_pe_2.tsv`).
2.  `SAMPLETABLE`: Path to a sample table where the 1st column is the
    prefix of the raw fastq files. The 4th column is the sample ID, the
    2nd column is the lane number, and the 3rd column is sequence ID.
    The combination of these three columns have to be unique. The 6th
    column should be data type, which is either pe or se
    (e.g. `/workdir/cod/greenland-cod/sample_lists/sample_table.tsv`).
3.  `RAWFASTQDIR`: Path to raw fastq files
    (e.g. `/workdir/backup/cod/greenland_cod/fastq/`).
4.  `BASEDIR`: Path to the base directory where adapter clipped fastq
    file are stored in a subdirectory titled `adapter_clipped` and into
    which output files will be written to separate subdirectories
    (e.g. `/workdir/cod/greenland-cod/`).
5.  `RAWFASTQSUFFIX1`: Suffix to raw fastq files. Use forward reads with
    paired-end data (e.g. `_R1.fastq.gz`).
6.  `RAWFASTQSUFFIX2`: Suffix to raw fastq files. Use reverse reads with
    paired-end data (e.g. `_R2.fastq.gz`).
7.  `ADAPTERS`: Path to a list of adapter/index sequences (e.g. for
    Nextera libraries: `/workdir/cod/reference_seqs/NexteraPE_NT.fa`,
    for BEST libraries: `/workdir/cod/reference_seqs/BEST.fa`).
8.  `TRIMMOMATIC`: Path to trimmomatic (default to
    `/programs/trimmomatic/trimmomatic-0.39.jar` if not specified).
9.  `THREADS`: Number of threads for trimmomatic to use (default to `8`
    if not specified).
10. `JOBS`: Number of trimmomatic jobs to run in parallel (default to
    `1` if not specified).

<br>

Below is an example taken from the Greenland cod project:

``` bash
nohup bash /workdir/data-processing/scripts/adapter_clipping.sh \
/workdir/cod/greenland-cod/sample_lists/sample_list_pe_2.tsv \
/workdir/cod/greenland-cod/sample_lists/sample_table.tsv \
/workdir/backup/cod/greenland_cod/fastq/ \
/workdir/cod/greenland-cod/ \
_R1.fastq.gz \
_R2.fastq.gz \
/workdir/cod/reference_seqs/NexteraPE_NT.fa \
/programs/trimmomatic/trimmomatic-0.39.jar \
8 \
4 \
>& /workdir/cod/greenland-cod/nohups/adapter_clipping_pe_2.nohup &
```

<br>

## Computer cluster

Submit the
[adapter\_clipping.slurm](https://github.com/therkildsen-lab/data-processing/blob/master/scripts/adapter_clipping.sh)
script with `sbatch` and use the `--export=VARIABLE_NAME=VALUE` command
to pass the following input variables **in any order**:

1.  `SERVER`: the server and the directory to mount to the computing
    node (e.g. `SERVER='cbsunt246 workdir/'` or
    `SERVER='cbsubscb16 storage/'`)
2.  `BASEDIR`: path to the base directory on the computing node (once
    mounting is complete) where adapter clipped fastq file are to be
    stored in a subdirectory titled `adapter_clipped`
    (e.g. `BASEDIR=/fs/cbsunt246/workdir/cod/greenland-cod/`).
3.  `SAMPLELIST`: path to a list of prefixes of the raw fastq files on
    the computing node. This should be a subset of the the 1st column of
    the sample table
    (e.g. `SAMPLELIST=/fs/cbsunt246/workdir/cod/greenland-cod/sample_lists/sample_list_pe_1.tsv`).
4.  `SAMPLETABLE`: path to a sample table on the computing node once
    mounting is complete
    (e.g. `SAMPLETABLE=/fs/cbsunt246/workdir/cod/greenland-cod/sample_lists/sample_table.tsv`),
    where the 1st column is the prefix of the raw fastq files, the 4th
    column is the sample ID, the 2nd column is the lane number, and the
    3rd column is sequence ID. The combination of these three columns
    have to be unique. The 6th column should be data type, which is
    either pe or se.
5.  `RAWFASTQDIR`: path to raw fastq files on the computing node once
    mounting is complete
    (e.g. `RAWFASTQDIR=/fs/cbsunt246/workdir/backup/cod/greenland_cod/fastq/`).
6.  `RAWFASTQSUFFIX1`: suffix to raw fastq files. Use forward reads with
    paired-end data (e.g. `RAWFASTQSUFFIX1=_R1.fastq.gz`).
7.  `RAWFASTQSUFFIX2`: suffix to raw fastq files. Use reverse reads with
    paired-end data (e.g. `RAWFASTQSUFFIX2=_R2.fastq.gz`).
8.  `ADAPTERS`: path to a list of adapter/index sequences on the
    computing node once mounting is complete. (e.g. for Nextera
    libraries, `ADAPTERS=/workdir/cod/reference_seqs/NexteraPE_NT.fa`
    and for BEST libraries,
    `ADAPTERS=/fs/cbsunt246/workdir/cod/reference_seqs/BEST.fa`).
9.  `TRIMMOMATIC`: path to trimmomatic
    (e.g. `TRIMMOMATIC=/programs/trimmomatic/trimmomatic-0.39.jar`).
10. `THREADS`: number of threads to use / number of “tasks” per array
    job (e.g. `THREADS=8`).
11. `ARRAY_LENGTH`: the number of array jobs to divide adapter clipping
    into (e.g. `ARRAY_LENGTH=10`). This must be less than or equal to
    the total number of samples in the SAMPLELIST. All samples will be
    divided among array jobs as evenly as possible.
12. `SCRIPT`: path to the adapter\_clipping.sh script on the computing
    node once mounting is complete
    (e.g. `SCRIPT=/fs/cbsunt246/workdir/data-processing/scripts/adapter_clipping.sh`).

In addition, you will need to provide the following slurm options:

1.  `--ntasks`: the number of threads per array job. This must be the
    same as the `THREADS` variable passed through `--export`
    (e.g. `--ntasks=8`).
2.  `--array`: the array length. This must be in the format of `1-n`,
    where `n` equals to the `ARRAY_LENGTH` variable passed through
    `--export` (e.g. `--array=1-10`).
3.  `--mem`: the maximum memory to be allocated to each array job
    (e.g. `--mem=3G`).
4.  `--partition`: the queue for each array job. This must be one of:
    short (max 4 hrs), regular (max 24 hrs), long7 (max 7 days), long30
    (max 30 days), or gpu (max 3 days) (e.g. `--partition=short`).

<br>

Below is an example taken from the Gulf of St. Lawrence cod project:

``` bash
sbatch --export=\
SERVER='cbsubscb16 storage/',\
BASEDIR=/fs/cbsubscb16/storage/cod/gosl-cod/,\
SAMPLELIST=/fs/cbsubscb16/storage/cod/gosl-cod/sample_lists/fastq_list_lane_13_best.txt,\
SAMPLETABLE=/fs/cbsubscb16/storage/cod/gosl-cod/sample_lists/sample_table_lane_13.tsv,\
RAWFASTQDIR=/fs/cbsubscb16/storage/backup/cod/gosl_cod/fastq/,\
RAWFASTQSUFFIX1=_1.fq.gz,\
RAWFASTQSUFFIX2=_2.fq.gz,\
ADAPTERS=/fs/cbsubscb16/storage/cod/reference_seqs/BEST.fa,\
TRIMMOMATIC=/programs/trimmomatic/trimmomatic-0.39.jar,\
THREADS=4,\
ARRAY_LENGTH=42,\
SCRIPT=/fs/cbsubscb16/storage/data-processing/scripts/adapter_clipping.sh \
--ntasks=4 \
--array=1-42 \
--mem=3000 \
--partition=short \
--output=/home/rl683/slurm/log/adapter_clipping_lane_13_best.log \
/fs/cbsubscb16/storage/data-processing/scripts/adapter_clipping.slurm
```

<br>

## Output

Output from this step are adapter clipped fastq files and they will be
written in the `adapter_clipped` folder under your project directory
(i.e. `BASEDIR`). A single file will be generated for each sample with
single-end data, and four different files will be generated for each
sample with paired-end data.

<br>

## Notes

-   `Trimmomatic` options are currently hardcoded. Please submit a
    GitHub issue if you would like them to be customizable.
