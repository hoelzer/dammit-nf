process dammitGetDB {
  if (params.full) {
    if (params.cloudProcess) { publishDir "${params.cloudDatabase}/dammit-full/${params.busco}", mode: 'copy', pattern: "dbs" }
    else { storeDir "nextflow-autodownload-databases/dammit-full/${params.busco}/" }  
  } else {
    if (params.cloudProcess) { publishDir "${params.cloudDatabase}/dammit/${params.busco}", mode: 'copy', pattern: "dbs" }
    else { storeDir "nextflow-autodownload-databases/dammit/${params.busco}/" }  
  }
    label 'dammitDB'
  input:
    path(busco_db)
  output:
    path("dbs", type: 'dir')
  script:
    if (params.full)
    """
    BUSCO=\$(echo ${params.busco} | awk 'BEGIN{FS="_"};{print \$1}')
    dammit databases --install --database-dir \${PWD}/dbs --busco-group \${BUSCO} --full
    # if the busco download fails use the busco db we downloaded before
    tar -zxvf ${busco_db} -C dbs/busco2db/
    """
    else
    """
    BUSCO=\$(echo ${params.busco} | awk 'BEGIN{FS="_"};{print \$1}')
    dammit databases --install --database-dir \${PWD}/dbs --busco-group \${BUSCO}
    # if the busco download fails use the busco db we downloaded before
    tar -zxvf ${busco_db} -C dbs/busco2db/
    """
}

