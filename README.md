# Nextflow -- dammit!
![](https://img.shields.io/badge/nextflow-20.01.0-brightgreen)
![](https://img.shields.io/badge/uses-docker-blue.svg)
![](https://img.shields.io/badge/licence-GPL--3.0-lightgrey.svg)

[![Twitter Follow](https://img.shields.io/twitter/follow/martinhoelzer.svg?style=social)](https://twitter.com/martinhoelzer) 

[Dammit](http://dib-lab.github.io/dammit/) is a simple but awesome pipeline for the annotation of transcripts -- a standard task that sounds fairly easy: given an input FASTA file with a bunch of sequences just tell me if there is any known homology and function I can assign to each sequence. 

Simple to say but difficult to do because of different tools, databases, software dependencies, merging of multiple annotation features, ... and in the end most users [just want an annotation, dammit!](http://dib-lab.github.io/dammit/about/).

The dammit pipeline developed by Camille Scott is already super usefull and quite easy to use. However, there are still some taks such as the download of all databases or distributing the pipeline on a HPC or Cloud that need additional work.

That's why I put the awesome tool into a Nextflow environmnet with Docker support! You only need Nextflow and Docker installed to execute the pipeline. Databases will be downloaded automatically (once) and there are only a few parameters that you need to pass to the workflow (see below). Using different profiles, the pipeline can be run on your local machine, a HPC, or the Google Cloud Platform.

# Execution

Basic execution on a local system (first `git clone` this repository):
```bash
nextflow run dammit.nf --fasta test/fungi_transcripts.fasta -profile local,docker --cores 4
```

You can also let Nextflow pull this repository:
```bash
nextflow run hoelzer/dammit-nf --fasta "/home/$USER/.nextflow/assets/hoelzer/dammit-nf/test/fungi_transcripts.fasta" -profile local,docker --cores 4
# update 
nextflow pull hoelzer/dammit-nf
```

On a HPC (such as LSF) you should set `--cachedir`, `--workdir`, and `--databases` to some meaningful locations with write permissions, e.g.:
```bash
nextflow run dammit.nf --fasta '*.fasta' --cachedir /hps/$USER/singularity --workdir /hps/$USER/nextflow-work --databases /hps/$USER/nextflow-dbs/dammit -profile lsf,docker,singularity
```

# Workflow

![image](https://github.com/hoelzer/dammit-nf/blob/master/figures/chart.png?raw=true)