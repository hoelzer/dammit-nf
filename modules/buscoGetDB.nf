process buscoGetDB {
    if (params.cloudProcess) { publishDir "${params.cloudDatabase}/busco/${params.busco}", mode: 'copy', pattern: "${params.busco}.tar.gz" }
    else { storeDir "nextflow-autodownload-databases/busco/${params.busco}" }  
    label 'dammitDB'
  output:
    file("${params.busco}.tar.gz")
  script:
    """
    wget http://busco.ezlab.org/v2/datasets/${params.busco}.tar.gz 
    """
}

/*
putting the database name into the channel for busco later on
*/