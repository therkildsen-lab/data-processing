# Data processing for low coverage whole genome sequencing 

Scripts for going from raw .fastq files to processed and quality-checked .bam files for downstream analysis

## Location of this repository

If you are working on the Therkildsen lab server, this GitHub repository is located at `/workdir/data-processing/`. Otherwise, clone this repo to the machine on which you are working. 

## Before you start

#### Create a project directory

As a first step, you should create a project directory (referred to as `BASEDIR` in certain scripts), with the following subdirectories:

  * `adapter_clipped` adapter clipped fastq files
  
  * `bam` bam files
  
  * `nohups` nohup log files
  
  * `sample_lists` sample tables and sample lists
   
  * `markdowns` markdown files tracking the workflow; it is recommended that you first create Rmd files using Rstudio, and knit these into GitHub markdown format

The following subdirectories are optional, depending on your workflow:

  * `angsd` angsd output files
  
  * `fastq` raw fastq files (if you don't already have it backed up on the backup folder)
  
  * `species_stats` fastq species detector output
  
  * `fastqc` FastQC output
  
  * `qual_filtered` quality filtered and/or polyG trimming
    
  * `scripts` scripts specific to your projects (e.g. merging certain bam files)

It is recommended that you make this project directory a separate GitHub repository. This way, you can track all the changes in your project directory. To make GitHub ignore certain directories (e.g. `adapter_clipped` and `bam`, since these will contain many large files), create a `.gitignore` file in your project directory, in which you specify the paths that should be ignored by git. 

#### Prepare sample lists

A sample list is a list of the prefixes of raw fastq files. These should be unique for each fastq file, and the rest of the names have to be the same for all raw fastq files. No header should be included in this list. 

You can have more than one sample list for each project; by doing so you will be able to run some of the scripts in parallel. When you have different suffixes for your raw fastq files (e.g when sequences come from different sequencing platforms), you will have to create multiple sample lists. 

Here is an example of a sample list: https://github.com/therkildsen-lab/greenland-cod/blob/master/sample_lists/sample_list_pe_1.tsv

#### Prepare a sample table

A sample table is a **tab deliminated** table that includes relevant information for all fastq files. It should include the following six columns, strictly in this order:

  * `prefix` prefix of raw fastq files; it should be the union of all your sample lists
  
  * `lane_number` lane number; each sequencing lane should be assigned a different number
  
  * `seq_id` sequence ID，this can be the same thing as sample ID or lane ID and it does not matter except for when different libraries were prepared out of the same sample and were run in the same lane. In this case, seq_id should be used to distinguish these.
  
  * `sample_id` sample ID
  
  * `population` population name
  
  * `data_type` data type; there can only be two possible entries: `pe` (for paired-end data) or `se` (for single end data)

It is important to make sure that the combination of lane_number, seq_id, and sample_id has to be unique for each fastq file. 

It is recommended that you have one single sample table per project. 

An example of a sample table: https://github.com/therkildsen-lab/greenland-cod/blob/master/sample_lists/sample_table.tsv

An example of how a sample table can be created from a list of fastq file names and the original sample infomation sheet: https://github.com/therkildsen-lab/greenland-cod/blob/master/markdowns/create_sample_table_se_3.md

#### Install programs used

If you are not working on the Therkildsen server, you might need to intall the following programs to your machine. Then you will also need to change the paths to these programs in the relavant scripts. 
 
 * `Trimmomatic` http://www.usadellab.org/cms/?page=trimmomatic
 * `fastp` https://github.com/OpenGene/fastp 
 * `bowtie2` http://bowtie-bio.sourceforge.net/bowtie2/index.shtml
 * `Picard` https://broadinstitute.github.io/picard/
 * `bamUtil` https://github.com/statgen/bamUtil
 * `GenomeAnalysisTK-3.7` https://software.broadinstitute.org/gatk/documentation/version-history.php?id=8692&page=3
 
## Get started

An example of the workflow: https://github.com/therkildsen-lab/greenland-cod/blob/master/markdowns/data_processing.md

## A few suggestions

1. Avoid using Excel to edit your sample tables and lists unless you know what you are doing, since it may lead to weird line ending issues. If you are encoutering such issues, read the file using R and write it again using functions such as `write_tsv()`
