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
params.panel = '/scratch/general/pe-nfs1/u0806040/varley_test/methPanel_v3_8_27_20'
if ( !params.panel ) { exit 1, "reference panel is not defined" }

params.ctseqSing = '/scratch/general/pe-nfs1/u0806040/varley_test/ctseq-v0.0.3.sif'
if ( !params.ctseqSing ) { exit 1, "ctseq singularity image not defined" }

params.fastq = false
if ( !params.fastq ) { exit 1, "full path to fastq files is not defined" }

params.run = false
if ( !params.run ) { exit 1, "name of run is not defined" }

params.info = '/scratch/general/pe-nfs1/u0806040/varley_test/methPanel_v3_infoFile.txt'
if ( !params.info ) { exit 1, "path to fragment info file is not defined" }

// logging 
log.info("\n")
log.info("Run name           (--run)             :${params.run}")
log.info("ctseq image        (--ctseqSing)       :${params.ctseqSing}")
log.info("Fastq directory    (--fastq)           :${params.fastq}")
log.info("Reference panel    (--panel)           :${params.panel}")
log.info("Fragment info file (--info)            :${params.info}")

// channel of combined fastqs
fastq_trios = channel.fromFilePairs("${baseDir}/combined/*_R{1,2,3}_001.fastq.gz", size: 3)

// run ctseq add_umis
process add_umis {
  stageInMode 'link'
  input:
    tuple val(id), path(fastqs)

  output:
    tuple val("${id}"), path("${id}_*ReadsWithUMIs.fastq")

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

/*
// run ctseq align
process align {
  input:
    path(${params.panel})

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

  output:
    path(${params.combined})

  script:
    """
    singularity exec ${params.ctseqSing} ctseq plot --dir ${params.combined} --fragInfo ${params.info}
    """
}
*/

workflow {
    add_umis(fastq_trios)
}
