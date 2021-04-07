nextflow.enable.dsl=2

params.help = false
if (params.help) {
    log.info"""
    ------------------------------------------------------------------
    ctseq-nf: a Nextflow workflow for ctseq
    See full details of ctseq at: https://github.com/ryanhmiller/ctseq
    Individual steps are run separately for parallelization
    ==================================================================

    Required arguments:
    -------------------
    --ctseqSing Path to the ctseq singularity image

    --panel     Path to reference panel

    --fastq     Path to fastqs

    --run       Run name used in final report and plots.

    --info      Path to frag info file
    ------------------------------------------------------------------
    """.stripIndent()
    exit 0
}

// required arguments
params.panel = false
if ( !params.panel ) { exit 1, "reference panel is not defined" }

params.fastq = false
if ( !params.fastq ) { exit 1, "full path to fastq files is not defined" }

params.run = false
if ( !params.run ) { exit 1, "name of run is not defined" }

params.info = false
if ( !params.info ) { exit 1, "path to fragment info file is not defined" }

// logging 
log.info("\n")
log.info("Run name           (--run)             :${params.run}")
log.info("ctseq image        (--ctseqSing)       :${params.fastq}")
log.info("Fastq directory    (--fastq)           :${params.fastq}")
log.info("Reference panel    (--panel)           :${params.panel}")
log.info("Fragment info file (--info)            :${params.info}")

// collapse lanes
process collapse {
  module 'python/3.5.2'  

  input:
    path(${params.fastq})
    path(${baseDir}/combineFiles.py)

  output:
    path(${baseDir}/combined)

  script:
    """
    python ${baseDir}/combineFiles.py -fastq ${params.fastq} -combined "${baseDir}/combined" -run ${params.run}
    """
}

// channel of combined fastqs
Channel
    .fromFilePairs("${baseDir}/combined/${params.run}*_{1,2,3}.fastq.gz", size: 3)
    .into { fastq }

/*
// run ctseq add_umis
process add_umis {
  input:
    path(${params.ctseqSing})

  output:

  script:
    """
    singularity exec ${params.ctseqSing} ctseq add_umis \
      --umiType separate \
      --umiLength 12 \
      --forwardExt R1_001.fastq.gz \
      --reverseExt R3_001.fastq.gz \
      --umiExt R2_001.fastq.gz \
    """
}

// run ctseq align
process align {
  input:
    path(${params.panel})
    path(${params.ctseqSing})

  output:

  script:
    """
    singularity exec ${params.ctseqSing} ctseq align \
      --refDir ${params.panel} \
      --cutadaptCores 18 \
      --bismarkCores 6 \
    """
}

// run ctseq call_molecules
process call_molecules {
  input:
    path(${params.panel})
    path(${params.ctseqSing})

  output:

  script:
    """
    singularity exec ${params.ctseqSing} ctseq call_molecules \
      --refDir ${params.panel} \
      --processes 10 \
    """
}

// run ctseq call_methylation
process call_methylation {
  input:
    path(${params.panel})
    path(${params.combined})
    path(${params.ctseqSing})

  output:

  script:
    """
    singularity exec ${params.ctseqSing} ctseq call_methylation \
      --refDir ${params.panel} \
      --dir ${params.combined} \
      --processes 10 \
      --nameRun ${params.run}
    """
}

// make the plots
process plot {
  input:
    path(${params.combined})
    path(${params.info})
    path(${params.ctseqSing})

  output:
    path(${params.combined})

  script:
    """
    singularity exec ${params.ctseqSing} ctseq plot --dir ${params.combined} --fragInfo ${params.info}
    """
}
*/
