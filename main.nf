#!/usr/bin/env nextflow

/*
vim: syntax=groovy
-*- mode: groovy;-*-
==============================================================================================================================
                                        N P - S I G N A L   P I P E L I N E
==============================================================================================================================

 Nanopore signal processing pipeline (Fast5)

 Documentation: https://github.com/np-core/np-signal

 Original development by Queensland Genomics, Australian Institute of Tropical Health 
 and Medicince, The Peter Doherty Intitute for Infection and Immunity

Developers:

    Eike Steinig  @esteinig  < @EikeSteinig >

Pipeline part of the NanoPath core framework:

    https://github.com/np-core

NanoPath distributed pipeline framework Netflow:

    https://github.com/np-core/netflow

For interactive dashboard operation and report generation:

    https://github.com/np-core/nanopath

----------------------------------------------------------------------------------------
*/

import java.nio.file.Paths

nextflow.enable.dsl=2

// Helper functions

def check_path(p, descr) {
    
    path = Paths.get(p)

    if (path.exists()){
        log.info"""
        Detected input path for $descr: $p
        """
    } else {
        log.info"""
        Failed to detect input path for $descr: $p
        """
        exit 0
    }
}

def get_matching_data( channel1, channel2 ){

    // Get matching data by ID (first field) from two channels
    // by crossing, checking for matched ID and returning
    // a combined data tuple with a single ID (first field)

    channel1.cross(channel2).map { crossed ->
        if (crossed[0][0] == crossed[1][0]){
            tuple( crossed[0][0], *crossed[0][1..-1], *crossed[1][1..-1] )
        } else {
            null
        }
    }
    .filter { it != null }

}


params.outdir = "$PWD/test_out"
params.alignment = ""
params.workflow = "ml"
params.dates = ""
params.raxml_model = "GTR+G+ASC_LEWIS"
params.raxml_params = ""
params.replicates = 100 // date randomisation test

if (params.dates){
    check_path(params.dates, "date file")
    dates = file(params.dates) // stage file
} else {
    dates = ""
}

// if (params.alignment){
//     check_path(params.alignment, "alignment file")
//     alignment = file(params.alignment) // stage file
// } else {
//     alignment = ""
// }

// Beastling

params.beast_xml = "$PWD/*.xml"
params.beast_params = ""
params.beagle_order = "0" // default cpu
params.beagle_instances = 2
params.beagle_gpu = false

// params.beast_threads defined in base config


if (params.beagle_gpu){
    beagle_params = "-beagle_gpu -beagle_order ${params.beagle_order}"
    if (params.beagle_order == "0"){
        log.info """
        Warning: BEAGLE GPU selected but BEAGLE order is set to 0 (usually CPU)
        """
    }
} else {
    beagle_params = "-beagle_cpu -beagle_sse -instances ${params.beagle_instances} -beagle_order ${params.beagle_order}"
}

// Workflow version

version = '0.1.3'

def helpMessage() {

    log.info"""
    =========================================
     N P - P H Y B E A S T  v${version}
    =========================================

    Usage (offline):

        nextflow run np-core/np-phybeast --workflow ml --alignment core.fasta --dates dates.tsv

    Deployment and resource configuration:

            Resources can be configured hierarchically by first selecting a configuration file from
            presets with `--config` and a resource presets with `--resource_config`

            Specific process execution profiles defined within the configuration files are selected with
            the native argument `-profile`

            For more information see: https://github.com/np-core/config 

    Subworkflow selection:

        --workflow                  select the variant subworkflow to select: ml, beast [${params.workflow}]
        --outdir                    output directory for results from workflow [${params.outdir}]

    Required:

        --alignment                 core genome variant alignment in FASTA format [${params.alignment}]
        --dates                     tab-delimited meta data file, must include columns: name, date [${params.dates}]

    Subworkflow - ML Phylodynamics:

        --raxml_model               model to construct tree in raxml-ng [${params.raxml_model}]
        --raxml_params              additional parameters to pass to raxml-ng [${params.raxml_params}]
        --replicates                number of date randomisation replicates [${params.replicates}]
    
    Subworkflow - BEAST Phylodynamics:
       
        --beast_xml                 glob to xml input files with unique names [${params.beast_xml}]
        --beast_params              string of additional beast parameters to specify ["${params.beast_params}"]
        --beast_threads             BEAST threads (SSE) to use when running on CPU [${params.beast_threads}]
        --beagle_instances          BEAGLE partition splits to run on BEAST threads in parallel [${params.beagle_instances}]
        --beagle_order              string device order to use in BEAGLE, 0 usually CPU, > 0 usually GPU ["${params.beagle_order}"]
        --beagle_gpu                explicitly activate GPU compute with BEAGLE [${params.beagle_gpu}]

    =========================================

    """.stripIndent()
}


params.help = false
if (params.help){
    helpMessage()
    exit 0
}

// Helper functions

def get_single_file( glob ){
    return channel.fromPath(glob) | map { file -> tuple(file.baseName, file) }
}


include { RAxML } from './modules/raxml'
include { TreeTime } from './modules/treetime'
include { VariantSites } from './modules/phybeast'
include { DateRandomisation } from './modules/phybeast'

// Basic phylogeny and phylodynamics based on ML 

workflow ml_phylodynamics {
    take:
        alignment  // id, aln
    main:
        VariantSites(alignment)
        RAxML(VariantSites.out)
        println alignment
        println RAxML.out
        TreeTime(RAxML.out, dates, alignment)
        DateRandomisation(RAxML.out, TreeTime.out[0], dates, alignment)
    emit:
        RAxML.out
}

// Advanced models on GPU using BEAST2 and BEAGLE

include { BeastCPU } from './modules/beast'
include { BeastGPU } from './modules/beast'

workflow beast_phylodynamics {
    take:
        xml // tuple id, xml
    main:
        if (params.beagle_gpu){
            beast = BeastGPU(xml, beagle_params)
        } else {
            beast = BeastCPU(xml, beagle_params)
        }
    emit:
        beast
}

workflow {
    if (params.workflow == "ml"){
        get_single_file(params.alignment) | ml_phylodynamics
    } else {
        get_single_file(params.beast_xml) | beast_phylodynamics
    }
}
