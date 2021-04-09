nextflow.enable.dsl=2

params.help = false
if (params.help) {
    log.info"""
    ------------------------------------------------------------------
    ctseq-nf: a Nextflow workflow for ctseq
    See full details of ctseq at: https://github.com/ryanhmiller/ctseq

    Individual steps are run separately for parallelization
 
    At present, ctseq singularity container does not have all needed
    functions to run nextflow, so nextflow wraps around the container
    rather than running inside the container
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

// required arguments: set defaults
params.ctseqSing = "${baseDir}/ctseq-v0.0.3.sif"

params.panel = "${baseDir}/methPanel_v3_8_27_20"

params.info = "${baseDir}/methPanel_v3_infoFile.txt"

// required arguments without defaults
params.fastq = false
if ( !params.fastq ) { exit 1, "full path to fastq files is not defined" }

params.run = false
if ( !params.run ) { exit 1, "name of run is not defined" }

// logging 
log.info("\n")
log.info("Run name           (--run)             :${params.run}")
log.info("ctseq image        (--ctseqSing)       :${params.ctseqSing}")
log.info("Fastq directory    (--fastq)           :${params.fastq}")
log.info("Reference panel    (--panel)           :${params.panel}")
log.info("Fragment info file (--info)            :${params.info}")

// channel of input fastqs
Channel
  .fromFilePairs("${baseDir}/Fastq/*_L00{1,2}_R{1,2,3}_001.fastq.gz", size: -1)
  .set { fastq_trios }

// run combineFiles.py
process combine_fastqs {
  publishDir path: "${baseDir}/combined", mode: "copy"

  module 'python/3.5.2'

  input:
    tuple val(id), path(fastqs)

  output:
    tuple val("${id}"), path("*_001.fastq.gz"), emit: combined_fastqs

  script:
    """
    cp ${baseDir}/by_sample_combine_files.py ./
    python ./by_sample_combine_files.py -s ${id}
    """
}

// run ctseq add_umis
process add_umis {
  module 'singularity/3.6.4'
  stageInMode 'link'
  publishDir path: "${baseDir}/combined", mode: "copy"

  input:
    tuple val(id), path(fastqs)

  output:
    tuple val("${id}"), path("*ReadsWithUMIs.fastq"), emit: umi_fastqs

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
  module 'singularity/3.6.4'
  publishDir path: "${baseDir}/combined", mode: "copy"

  input:
    tuple val(id), path(fastqs)

  output:
    tuple val("${id}"), path("*.sam"), emit: sam
    path("*bt2_PE_report.txt"), emit: bismark_reports

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
  module 'singularity/3.6.4'
  publishDir path: "${baseDir}/combined", mode: "copy"

  input:
    tuple val(id), path(sam)

  output:
    path("*_allMolecules.txt"), emit: allMolecules

  script:
    """
    singularity exec ${params.ctseqSing} ctseq call_molecules \
      --refDir ${params.panel} \
      --processes 10 \
    """
}

// run ctseq call_methylation
process call_methylation {
  module 'singularity/3.6.4'
  publishDir path: "${baseDir}/results_summary", mode: "copy"

  input:
    path(bismark_reports)
    path(allMolecules)

  output:
    path("${params.run}_totalMolecules.txt"), emit: totalMolecules
    path("${params.run}_methylatedMolecules.txt"), emit: methylatedMolecules
    path("${params.run}_totalReads.txt"), emit: totalReads
    path("${params.run}_methylationRatio.txt"), emit: methylationRatio
    path("${params.run}_runStatistics.txt"), emit: runStatistics

  script:
    """
    singularity exec ${params.ctseqSing} ctseq call_methylation \
      --refDir ${params.panel} \
      --processes 10 \
      --nameRun ${params.run}
    """
}

// make the plots
process plot {
  module 'singularity/3.6.4'
  publishDir path: "${baseDir}/results_plots", mode: "copy"

  input:
    path(totalMolecules)
    path(methylatedMolecules)
    path(totalReads)
    path(methylationRatio)
    path(runStatistics)

  output:
    path("${params.run}_totalMoleculesPlot.pdf")
    path("${params.run}_totalMoleculesHeatmap.pdf")
    path("${params.run}_methylatedMoleculesHeatmap.pdf")
    path("${params.run}_methylationRatioHeatmap.pdf")

  script:
    """
    singularity exec ${params.ctseqSing} ctseq plot --fragInfo ${params.info}
    """
}

workflow {
    combine_fastqs(fastq_trios)
    add_umis(combine_fastqs.out.combined_fastqs)
    align(add_umis.out.umi_fastqs)
    call_molecules(align.out.sam)
    call_methylation(align.out.bismark_reports.collect(), call_molecules.out.allMolecules.collect())
    plot(call_methylation.out.totalMolecules, call_methylation.out.methylatedMolecules, call_methylation.out.totalReads, call_methylation.out.methylationRatio, call_methylation.out.runStatistics)
}
