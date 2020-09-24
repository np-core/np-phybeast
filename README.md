# np-phybeast

![](https://img.shields.io/badge/lang-nextflow-41ab5d.svg)
![](https://img.shields.io/badge/version-0.1.0-addd8e.svg)
![](https://img.shields.io/badge/biorxiv-v0-f7fcb9.svg)

Phylodynamic workflows for bacterial pathogens using short- and long-read (nanopore) sequencing data :sauropod:


```
nextflow run np-core/np-phybeast --help true
```

## Usage 

```
=========================================
   N P - P H Y B E A S T  v${version}
=========================================

Usage:

A typical command for reconstructing the maximum-likelihood tree from core genome variants:

    nextflow run np-core/np-phybeast --alignment core.fasta --tree_builder raxml-ng 

```

## Description

`Phybeast` is a pipeline for lineage-based phylogenetic and -dynamic analyses of bacterial pathogens. In its simplest incarnation it is meant to provide a phylogenomic history of a particular lineage such as the [Bengal Bay (ST772-MRSA)](https://mbio.asm.org/content/10/6/e01105-19) or the [Queensland clone (ST93-MRSA)]() of *Staphylococcus aureus*. 

We also endeavour to implement somewhat standardized procedures for more complex phylodynamic analyses based on maximum-likelihood and Bayesian approahes in `BEAST2`. We hope that this makes these analyses more convenient and accessible, either directly from sequence reads, and provide some degree of standardisation for lineage-focused phylogenetics and -dynamics in bacterial pathogens.

Hybrid phylogenies using a combined alignment of high-quality Illumina core variants and multiplex nanopore panels to contextualise nanopore isolates within a lineage's evolutionary history (e.g. for outbreak divergence dating) can be constructed using the `np-core/np-variants` workflow for `Megalodon`, as described below.

## Workflows

### Maximum-likelihood Phylodynamics

```
nextflow run np-core/np-phybeast --alignment core.snps.fasta --raxml_model GTR+G+ASC_LEWIS
```

Basic workflow to construct an ML phylogeny from the provided alignment, check the dated root-to-tip regression signal, perform a date-randomisation test and generate time-scaled ML phyogeny and Skyline plot of effective population size via [`TreeTime`](https://github.com/neherlab/treetime).

Modules:

* Phybeast (variant sites, date randomisation)
* RAxML-NG (phylogeny)
* TreeTime (phylodynamics)

### Beastling Phylodynamics

`Beastling` is a submodule of `NanoPath` which aims to make the exploration of complex phylodynamic models in `BEAST2` a little easier, and to scale multiple prior configurations of the models on clusters or `GPU` using `BEAGLE 3`. Since prior configurations can have strong impacts on the results of the models, this workflow will require you to prepare `Beastling` configuration files for your datasets.

Supported models and their tags:

* *Birth-Death Skyline Serial* (`bdss`)
* *Birth-Death Skyline Contemporary* (`bdsc`)
* *Multi-type Birth Death* (`mtbd`)
* *Coalescent Bayesian Skyline* (`cosky`)

**Step 1**

Prepare the `YAML` configuration files with your prior specification and model settings. Templates can be found at [`np-core/nanopath/nanopath/templates`](https://github.com/np-core/nanopath/tree/master/nanopath/templates) or can be produced with the corresponding tag:

```
np beastling template --model bdss --out bdss.yaml
```

Configuration files are split into three sections: prior configuration (`priors`), interval configuration (`intervals`) and clock configurations (`clock`). Clock selection can be conducted on the command-line and intervals have to be explicitly enabled to generate the `XML`.

For example the `Birth-Death Skyline Serial` configuration file looks like this, where the sampling proportion prior is fixed at zero from the `Origin` to the first sample in the collection (1991). Interval chnage times must include the most recent change point (`0`):

```yaml
priors:
  model: # Model priors [all]
    origin:
      distribution: gamma
      dimension: 1
      initial: 50.0
      lower: 0
      upper: infinity
      alpha: 2.0
      beta: 40.0
      mode: shape_mean
    reproductive_number:
      distribution: gamma
      dimension: 5
      initial: 2.0
      lower: 0
      upper: infinity
      alpha: 2.0
      beta: 2.0
      mode: shape_mean
    become_uninfectious:
      distribution: lognormal
      dimension: 1
      initial: 1.0
      lower: 0
      upper: infinity
      mean: 0.05
      sd: 0.5
      real_space: true
    sampling_proportion:
      distribution: beta
      dimension: 1
      initial: 0.01
      lower: 0
      upper: 1.0
      alpha: 1.0
      beta: 1.0
  intervals:
    sampling_proportion: # pre-sampling / contemporary sampling slicing
      change_times: [28.1, 0]
      intervals: # ordered list of dicts matching change_times
        - distribution: exponential
          initial: 0 # zero fixing (origin - 1991)
          mean: 1e-08
        - distribution: beta # flat prior as we have no clue (1991 - 2019)
          initial: 0.01
          alpha: 1.0
          beta: 1.0
  clock: # Clock priors [selected in command-line]
    rate: # strict
      distribution: lognormal
      dimension: 1
      initial: 5.0e-04
      lower: 0
      upper: infinity
      mean: 3e-04
      sd: 0.3
      real_space: true
    uced: # relaxed exponential
      distribution: lognormal
      dimension: 1
      initial: 5.0e-04
      lower: 0
      upper: infinity
      mean: 3e-04
      sd: 0.3
      real_space: true
    ucld_mean: # relaxed lognormal
      distribution: lognormal
      dimension: 1
      initial: 5.0e-04
      lower: 0
      upper: infinity
      mean: 3e-04
      sd: 0.3
      real_space: true
    ucld_sd: # relaxed lognormal
      distribution: lognormal
      dimension: 1
      initial: 5.0e-04
      lower: 0
      upper: infinity
      mean: 3e-04
      sd: 0.3
      real_space: true
```
