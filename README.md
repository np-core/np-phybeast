# np-phybeast

![](https://img.shields.io/badge/lang-nextflow-41ab5d.svg)
![](https://img.shields.io/badge/version-0.1.0-addd8e.svg)
![](https://img.shields.io/badge/biorxiv-v0-f7fcb9.svg)

Phylogenetics and -dynamics for bacterial pathogens using short- and long-read (nanopore) sequencing data :sauropod:


```
nextflow run np-core/np-phybeast --help true
```

## Usage 

```
=========================================
   N P - P H Y B E A S T  v${version}
=========================================

Usage:

A typical command for reconstructing the reference alignment and maximum-lilihood tree is:

    nextflow run np-core/np-phybeast --illumina fastq/ --tail "_R{1,2}.fastq.gz" --tree_builder raxml-ng 

```


## Description

`Phybeast` is a pipeline for lineage-based phylogenetic and -dynamic analyses of bacterial pathogens. In its simplest incarnation it is meant to provide a phylogenomic history of a particular lineage such as the [Bengal Bay (ST772-MRSA)](https://mbio.asm.org/content/10/6/e01105-19) or the [Queensland clone (ST93-MRSA)]() of *Staphylococcus aureus*. In addition to state-of-the-art workflows to reconstruct phylogenies from high-quality short-read data we endeavour to implement somewhat standardized procedures for more complex phylodynamic analyses based on maximum-likelihood and Bayesian approahes in `BEAST2`. We hope that this makes these analyses more convenient and accessible, either directly from sequence reads, and provide some degree of standardisation for lineage-focused phylogenetics and -dynamics in bacterial pathogens.


