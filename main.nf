nextflow.enable.dsl=2

params.help = false
if (params.help) {
    log.info"""
    ------------------------------------------------------------------
    ctseq-nf: a Nextflow workflow for ctseq
    See full details of ctseq at: https://github.com/ryanhmiller/ctseq
    ==================================================================

    Required arguments:
    -------------------
    --ctseqSing Path to the ctseq singularity image

    --panel     Path to reference panel

    --fastq     Path to fastqs

    --run       Run name used in final report and plots.

    --info      Path to feag info file
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
    path(${params.combined})

  script:
    """
    python ${baseDir}/combineFiles.py -fastq ${params.fastq} -combined "${baseDir}/combined" -run ${params.run}
    """
}

// run ctseq analyze
process ctseq {
  input:
    path(${params.panel})
    path(${params.combined})
    path(${params.ctseqSing})

  output:
    path(${params.combined})

  script:
    """
    singularity exec ${params.ctseqSing} ctseq analyze \
      --refDir ${params.panel} \
      --dir ${params.combined} \
      --umiType separate \
      --umiLength 12 \
      --forwardExt R1_001.fastq.gz \
      --reverseExt R3_001.fastq.gz \
      --umiExt R2_001.fastq.gz \
      --cutadaptCores 18 \
      --bismarkCores 6 \
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
