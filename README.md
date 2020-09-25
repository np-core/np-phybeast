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


## Configuration

For resource configuration selection, please see: [`np-core/configs`](https://github.com/np-core/configs)

Containers:

* Docker tag: `np-core/phybeast:latest`
* Singularity image: `phybeast-latest.sif`

System configs:

* **Default configuration**: `nextflow`
* James Cook University cluster: `jcu`
* NECTAR cloud: `nectar`

Resource configs (default config):

* Local server: `process`

Profile configs (default config):

* `docker` / `docker_gpu`
* `singularity` / `singularity_gpu`

## Workflows

### Maximum-Likelihood Phylodynamics

```
nextflow run np-core/np-phybeast -profile docker --worklow ml --alignment core.snps.fasta --raxml_model GTR+G+ASC_LEWIS
```

Basic workflow to construct an ML phylogeny from the provided alignment, check the dated root-to-tip regression signal, perform a date-randomisation test and generate time-scaled ML phyogeny and Skyline plot of effective population size via [`TreeTime`](https://github.com/neherlab/treetime).

Modules:

* Phybeast (variant sites, date randomisation)
* RAxML-NG (phylogeny)
* TreeTime (phylodynamics)

### `BEAST` Phylodynamics

`Beastling` is a submodule of `NanoPath` which aims to enable the exploration of complex phylodynamic models for bacterial pathogens in `BEAST2` and to scale multiple model configurations on `GPU` or `CPU` clusters using `BEAGLE 3`. Since prior configurations can have strong impacts on the results of the models, this workflow will require you to prepare sensible prior configurations for your data before launching the computation on the `XML` files. `Beastling` configuration templates are available and can be conveniently configured from the command line (**Steps 1 and 2**) or you can generate the `XML` inputs for your models manually; `XML` templates for supported models can be found in [`np-core/nanopath/nanopath/templates`](https://github.com/np-core/nanopath/tree/master/nanopath/templates))

Supported models and their `Beastling` tags:

* *Birth-Death Skyline Serial* (`bdss`)
* *Birth-Death Skyline Contemporary* (`bdsc`)
* *Multi-type Birth Death* (`mtbd`)
* *Coalescent Bayesian Skyline* (`cosky`)

#### `Beastling` Configuration

Prepare the `YAML` configuration files with your prior specification and model settings. Templates can be produced with the corresponding tag:

```
np beastling template --model bdss --out bdss.yaml
```

Prior configuration (`priors`) is split into three sections: model priors (`model`), prior intervals (`intervals`) and clock configurations (`clock`). Please see below for sensible specifications of these models for bacterial pathogens. It is strongly recommended to run various dimensional slice settings on the reproduction number prior, as these may have relatively large impacts on the posterior distributions of all parameters. Slice or interval settings for sampling proportions are also recommended. Please note that the `BDSky` models are sensitive to population structure (e.g. phylogenetic divergences) and generally assume a mixed population - unintended and difficult-to-detect effects on posterior estimates across the model parameters can occur when structured populations are included.

For example, a potential `Birth-Death Skyline Serial` configuration looks like this: the sampling proportion prior is fixed at zero from the `Origin` to the first sample in the collection (1991). Interval change times must include the most recent change point (`0`) and must be specified forward in time (most recent change point last):

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

#### `Beastling` XML

Configuration files allow you to modify various parameters without having to change the actual `XML` or generating a new `XML` in `BEAUTi`. Model configuration files can then be passed to the corresponding task on the command line ti generate the `XML`:

```
np beastling xml-bdss --alignment core.snps.fasta --data meta.tsv --yaml bdss.yaml --prefix run1 --length 1000000000
```

Clock selection can be conducted on the command-line (`--clock strict`) and intervals have to be explicitly enabled (`--intervals`).

Metropolis-coupled MCMC chains can be selected using `--mcmc coupled` and the number of hot chains can be set with `--hot <int>` - however, for some models like the *Multi-type Birth-Death* the coupled chain is not currently functional.

#### `Phybeast` Workflow

Run the `beast` workflow on a glob of `XML` files generated using our wrappers (or manually):

```
nextflow run np-core/np-phybeast --config jcu -profile tesla --workflow beast --beast_xml "*.xml" --beagle_gpu true --beagle_order 1
```

**If you are running on GPU, you must explicitly enable `--beagle_gpu true` and set the correct device for exampple `--beagle_order 1`**

#### `BEAGLE` Settings 

`BEAGLE` with `SSE` support is preinstalled into the container and used for `CPU` and `GPU` acceleration. I noticed that best performance on `CPU` depend on setting both the `-instances` (divides the partition site patterns) and `-threads` parameter when running `BEAST`, where `-instances` should not be larger than `-threads`. When both are set to the same value (if there are a large number of site patterns) or `-threads` is higher than `-instances` (when the number of site patterns is smaller), and `SSE` is activated, there is a solid boost to performance on `CPU`. 

`GPU` performance is always much higher than `CPU`, but the number of simultaneous runs or coupled chains on a single `GPU` will slow the computation time by a factor of the number of runs or chains running on the device.

Benchmarks were conducted on the `Birth-Death Skyline Serial` model using a dataset of 575 bacterial isolates and a core-genome alignment of around 7000 SNPs (somewhat few site patterns)

| Run **            | Minutes ***   | Minimal command                                           |
| -------------     | ------------- |-----------------------------------------------------------|
| CPU (t: 4, i: 4)  | 37:28 min     | `beast -beagle_cpu -beagle_sse -threads 4 -instances 4`   |
| CPU (t: 8, i: 4)  | 51:00 min     | `beast -beagle_cpu -beagle_sse -threads 8 -instances 4`   |
| CPU (t: 8, i: 8)  | 51:00 min     | `beast -beagle_cpu -beagle_sse -threads 8 -instances 8`   |
| GPU (GTX1080-TI)  | 07:08 min     | `beast -beagle_gpu`                                       |

**  `-seed 777`, time assessed at step 500k
*** time in minutes per million steps on a standard MCMC


####


