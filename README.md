# np-phybeast

![](https://img.shields.io/badge/lang-nextflow-41ab5d.svg)
![](https://img.shields.io/badge/version-0.1.0-addd8e.svg)
![](https://img.shields.io/badge/biorxiv-v0-f7fcb9.svg)

Outbreak phylogenetics and -dynamics for bacterial pathogens using nanopore sequencing

## Overview

**`v0.1.0: first release`**

`Phybeast` is a pipeline for lineage-based phylogenetic and -dynamic analyses of bacterial pathogens. In its simplest incarnation, it is meant to provide a model of the evolutionary history of a particular lineage, for example the Bengal Bay clone (ST772-MRSA) or the Queensland clone (ST93-MRSA). In addition to state-of-the-art workflows to reconstruct phylogenies from high-quality short-read data, we endeavour to implement somewhat standardized procedures for more complex phylodynamic analyses based on maximum-likelihood approaches and eventually, wrapping analyses from `BEAST`. We hope that this makes these analyses more convenient and accessible, either directly from sequence reads, and provide some degree of standardisation for lineage-focused phylogenetics and -dynamics in bacterial pathogens.

Moreover, population-wide sequence data allows us to contextualise newly sequenced isolates within a lineage's background variation, for instance, if we acquire a set of isolates from a novel outbreak of a known lineage. Our main aim is the contextualisation of nanopore sequence data within the pathogen population. Under normal circumstances, we would require *de novo* variant calling, which is still difficult for nanopore sequence data, particularly at low sequencing depth, for instance if we want to cost-effectively multiplex isolates on a single flowcell. However, our strategy implemented here first infers the core genetic variants (single nucleotide polymorphisms) from a known lineage population and uses the variants as candidates for calls from low-coverage nanopore data using Megalodon. While there are some caveats associated with this method, it allows us to integrate barcoded isolates sequenced on nanopore devices into the evolutionary context of a pathogen and conduct more sophisticated analyses on hybrid data sets. We hope that this will provide a path forward to shorten the time-span from sampling to sequencing to meaningful phylogenetic analyses using nanopore data alone, and to enable these analyses in locations where short-read sequencing may not be easily accessible.
