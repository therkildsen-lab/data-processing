# data-processing
Scripts for going from raw .fastq files to processed and quality-checked .bam files for downstream analysis

If you are working on the Therkildsen lab server, this GitHub repository is located at `/workdir/data-processing/`. Otherwise, clone this repo to the machine that you are working. 

As a first step, you should create a project directory (referred to as `BASEDIR` in certain scripts), with the following subdirectories:

```
adapter_clipped # Adapter clipped fastq files
bam # Bam files
nohups  # Nohup log files
sample_lists # Sample tables and sample lists
```

The following subdirectories are optional, depending on your workflow:

```
angsd # Angsd output files
fastq # Raw fastq files
species_stats # Fastq species detector output
fastqc # FastQC output
qual_filtered # Quality filtered and/or polyG trimming
markdowns # Markdown files tracking the workflow, and some Rmd files on data exploration
scripts # Scripts specific to your projects (e.g. merging certain bam files)
```

It is recommended that you make this project directory a separate GitHub repository. This way, you can track all the changes in your project directory. To make GitHub ignore certain directories (e.g. `adapter_clipped` and `bam`, since these will contain many large files), create a `.gitignore` file in your project directory, in which you specify the paths that should be ignored by git. 

An example of the workflow: https://github.com/therkildsen-lab/greenland-cod/blob/master/markdowns/data_processing.md

