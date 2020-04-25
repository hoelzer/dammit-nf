#!/usr/bin/env nextflow
nextflow.preview.dsl=2

/*
* Nextflow -- annotate transcripts with dammit
* Author: hoelzer.martin@gmail.com
*/

/************************** 
* Help messages, user inputs & checks
**************************/

if( !nextflow.version.matches('20.+') ) {
    println "This workflow requires Nextflow version 20.X or greater -- You are running version $nextflow.version"
    exit 1
}

if (params.help) { exit 0, helpMSG() }

println " "
println "\u001B[32mProfile: $workflow.profile\033[0m"
println " "
println "\033[2mCurrent User: $workflow.userName"
println "Nextflow-version: $nextflow.version"
println "Starting time: $nextflow.timestamp"
println "Workdir location:"
println "  $workflow.workDir\u001B[0m"
println " "
if (workflow.profile == 'standard') {
println "\033[2mCPUs to use: $params.cores"
println "Output dir name: $params.output\u001B[0m"
println " "}

if (params.profile) {
    exit 1, "--profile is WRONG use -profile" }
if (!params.fasta) {
    exit 1, "input missing, use [--fasta]"}
    
// fasta input
    if (params.fasta && params.list) { fasta_input_ch = Channel
            .fromPath( params.fasta, checkIfExists: true )
            .splitCsv()
            .map { row -> [row[0], file("${row[1]}", checkIfExists: true)] }
            .view() }
    else if (params.fasta) { fasta_input_ch = Channel
            .fromPath( params.fasta, checkIfExists: true, type: 'file')
            .map { file -> tuple(file.simpleName, file) }
            .view() }

/************************** 
* MODULES
**************************/
  
include buscoGetDB from './modules/buscoGetDB'
include dammitGetDB from './modules/dammitGetDB'
include dammit from './modules/dammit'

/************************** 
* DATABASES
**************************/

/* Comment section:
The Database Section is designed to "auto-get" pre prepared databases.
It is written for local use and cloud use via params.cloudProcess.
*/
workflow download_busco {
    main:
        if (!params.cloudProcess) { buscoGetDB() ; database_busco = buscoGetDB.out }
        if (params.cloudProcess) { 
            busco_db_preload = file("${params.cloudDatabase}/busco/${params.busco}/${params.busco}.tar.gz")
            if (busco_db_preload.exists()) { database_busco = busco_db_preload }
            else  { buscoGetDB(); database_busco = buscoGetDB.out }
        }
    emit: database_busco
}

workflow download_dammit {
    take: 
    busco_db_ch
    
    main:
        if (!params.cloudProcess) { dammitGetDB(busco_db_ch) ; database_dammit = dammitGetDB.out }
        if (params.cloudProcess) {
            if (params.full) {
                dammit_db_preload = file("${params.cloudDatabase}/dammit-full/${params.busco}/dbs")
            } else {
                dammit_db_preload = file("${params.cloudDatabase}/dammit/${params.busco}/dbs")
            }
            if (dammit_db_preload.exists()) { database_dammit = dammit_db_preload }
            else  { dammitGetDB(busco_db_ch); database_dammit = dammitGetDB.out }
        }
    emit: database_dammit
}


/************************** 
* SUB WORKFLOWS
**************************/

workflow annotation_wf {
    take:  
        fasta_input_ch
        dammit_db_ch
        
    main:
        dammit(fasta_input_ch, dammit_db_ch)
}

/************************** 
* MAIN WORKFLOW 
**************************/

workflow {

    // databases
    busco_db = download_busco()
    dammit_db = download_dammit(busco_db)

    // run dammit
    annotation_wf(fasta_input_ch, dammit_db)
}


/*************  
* --help
*************/

def helpMSG() {
    c_green = "\033[0;32m";
    c_reset = "\033[0m";
    c_yellow = "\033[0;33m";
    c_blue = "\033[0;34m";
    c_dim = "\033[2m";
    log.info """
    ____________________________________________________________________________________________
    
    Annotate it, dammit! -- with Nextflow.

    ${c_yellow}Usage example:${c_reset}
    nextflow run dammit.nf --fasta '*/*.fasta' 

    ${c_yellow}Input:${c_reset}
    ${c_green} --fasta ${c_reset}       '*.fasta'           -> one FASTA file per transcriptome assembly
    ${c_dim}  ..change above input to csv:${c_reset} ${c_green}--list ${c_reset}
    
    ${c_yellow}Options:${c_reset}
    --cores             max cores for local use [default: $params.cores]
    --memory            memory limitations for polisher tools in GB [default: $params.memory]
    --output            name of the result folder [default: $params.output]
    --full              load the uniref90 database ((large! takes ages!)) [default: $params.full]
    --busco             the database used with BUSCO [default: $params.busco]
      ${c_dim}full list of available data sets at https://busco.ezlab.org/v2/frame_wget.html${c_reset}

    ${c_dim}Nextflow options:
    -with-report rep.html    cpu / ram usage (may cause errors)
    -with-dag chart.html     generates a flowchart for the process tree
    -with-timeline time.html timeline (may cause errors)

    ${c_yellow}LSF computing:${c_reset}
    For execution of the workflow on a HPC with LSF adjust the following parameters:
    --databases         defines the path where databases are stored [default: $params.cloudDatabase]
    --workdir           defines the path where nextflow writes tmp files [default: $params.workdir]
    --cachedir          defines the path where images (singularity) are cached [default: $params.cachedir] 

    Profile:
    Please merge profiles
    -profile                 local,docker (conda also available)
                             lsf,docker (HPC w/ LSF, singularity/docker)
                             lsf,docker, singularity (adjust workdir and cachedir according to your HPC config)
                             gcloudMartin,docker (googlegenomics with docker)
                             ${c_reset}
    """.stripIndent()
}

