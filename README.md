# ctseq-nf
A Nextflow workflow for `ctseq` to enable parallel deployment of jobs across many nodes.  
See full details of ctseq here: `https://github.com/ryanhmiller/ctseq`  
`ctseq-nf` runs each step of `ctseq analyze` as Nextflow process, allowing for parallel  
deployment of jobs across any number of nodes.  
`ctseq-nf` will also manage resoruce allocation and request greater resources  
when jobs with a large number of reads fail.  

# Usage
`nextflow run ctseq-nf --fastq [full path to raw fastqs] --run [sequening run ID]`

## Default values for requried input files
+ `--panel`
    + The methalyation panel
    + "${baseDir}/methPanel_v3_8_27_20"
+ `--ctseqSing`
    + The Singularity container with `ctseq`
    + "${baseDir}/ctseq-v0.0.3.sif"
+ `--info`
    + The fragment info file required for plotting
    + "${baseDir}/methPanel_v3_infoFile.txt"

Users can override these defaults at the command line on launching the workflow. 

## Overview
+ Fastqs are combined by lane
+ UMIs are added
+ Alignments with Bismark
+ Call molecules
+ Combine all samples to call methylation for entire run
+ Plot

## Note about Singularity
At present, the freely available Singularity contaier does not have all resources  
needed to run Nextflow. Therefore, each step of `ctseq-nf` invokes the container and  
watches for the output to appear in the working directory. A furture implemtation may  
involve an updated container with all necessary dependences for Nextflow.  
