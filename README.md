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

`Phybeast` is a pipeline for lineage-based phylogenetic and -dynamic analyses of bacterial pathogens. In its simplest incarnation it is meant to provide a ML phylogenetic tree and basic ML-based phylodemographic estimates of a particular lineage, such as the [Bengal Bay (ST772-MRSA)](https://mbio.asm.org/content/10/6/e01105-19) or the [Queensland clone (ST93-MRSA)]() of *Staphylococcus aureus*. 

We endeavour to implement a somewhat standardized procedures for more complex phylodynamic analyses based on maximum-likelihood and Bayesian approaches in `BEAST2`. We hope that this makes these analyses more convenient and accessible, and provide some degree of standardisation for lineage-focused phylogenetics and -dynamics in bacterial pathogens.

Hybrid phylogenies using a combined alignment of high-quality Illumina core variants and multiplex nanopore panels to contextualise nanopore isolates within a lineage's evolutionary history (e.g. for outbreak divergence dating) can be constructed using the `np-core/np-variants` workflow for `Megalodon`, as described below.


## Configuration

For resource configuration selection, please see: [`np-core/configs`](https://github.com/np-core/configs)

Containers:

* Docker tag: `np-core/phybeast:latest`
* Singularity image e.g. `$HOME/phybeast-latest.sif`

System configs:

* **Default system configuration**: `default`
* James Cook University (McBryde group): `envs/jcu`
* NECTAR (Coin group): `envs/nectar`

Resource configs (default config):

* **Default resource configuration**: `default`

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

#### 1. `Beastling` Configuration

Prepare the `YAML` configuration files with your prior specification and model settings. Templates can be produced with the corresponding tag:

```
np beastling config --model bdss --out bdss.yaml
```

Prior configuration (`priors`) is split into three sections: model priors (`model`), prior intervals (`intervals`) and clock configurations (`clock`). Sensible prior configurations of  models for different bacterial pathogens are highly dependent on the dataset and species. The example below is from *Staphylococcus aureus* (ST93 intra-lineage, ~7000 core genome SNPs, n = 575). It is strongly recommended to run various dimensional slice settings on the reproduction number prior, as these have been observed to have relatively large impacts on the posterior distributions of all parameters. Slice or interval settings for sampling proportions are also recommended, usually with a zero fixing towards the origin, before the first sample in the collection. 

**Note on model assumptions**:

Please note that the `Birth-Death Skyline` models are sensitive to population structure (e.g. phylogenetic divergences) and generally assume a mixed population - unintended and difficult-to-detect effects on posterior estimates across the model parameters can occur when highly structured populations are included and the effects may be difficult to tease aparts. We have observed this effect in a lineage-wide comparison of *S. aureus* sequence types in the ST93 lineage with strong substructure between ancestral MSSA and divergent MRSA clades and in particular the estimate of the become uninfectious rate, where the result was strongly driven by the prior (resulting in a substantially shorter infection period compared to other lineages. It was not observed when running the model on the MSSA and divergent MRSA population independently in which case the model estimated more realistic values for the become uninfectious rate. Setting a realistic prior distribution informed by esitimates from the literature and estimated rates across other lineages, ultimately corrected this effect but it may be hard to detect. Models can be run independently on less structured subclades in the ML phylogeny of the genome collection. *Multi-Type Birth Death* models are more suited to highly structured populations, where subpopulations can be defined as demes. However, their application to bacterial data is currently not well explored by us and preliminary runs on ST93 and other sequence types did not converge. We have included them in `Beastling` for further testing.

**Example configuration**:

A `Birth-Death Skyline Serial` configuration can look like this: the sampling proportion prior is fixed at zero from the `Origin` to the first sample in the collection (1991). Interval change times must include the most recent change point (`0`) and must be specified forward in time (most recent change point last):

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

#### 2. `Beastling` XML

Configuration files allow you to modify various parameters without having to change the actual `XML` or generating a new `XML` in `BEAUTi`. Model configuration files can then be passed to the corresponding task on the command line ti generate the `XML`:

```
np beastling xml-bdss --alignment core.snps.fasta --data meta.tsv --yaml bdss.yaml --prefix run1 --length 1000000000
```

Clock selection can be conducted on the command-line (`--clock strict`) and intervals have to be explicitly enabled (`--intervals`).

Metropolis-coupled MCMC chains can be selected using `--mcmc coupled` and the number of hot chains can be set with `--hot <int>` - however, for some models like the *Multi-type Birth-Death* the coupled chain is not currently functional.

#### 3. `Phybeast` Workflow

Run the `beast` workflow on a glob of `XML` files generated using our wrappers (or manually):

**If you are running on GPU, you must explicitly enable `--beagle_gpu true` and set the correct device, for example: `--beagle_order 1`**

```
nextflow run np-core/np-phybeast --config jcu -profile tesla --workflow beast --beast_xml "*.xml" --beagle_gpu true --beagle_order 1
```

#### `BEAGLE` Settings 

`BEAGLE` with `SSE` support is preinstalled into the container and can be used for `CPU` and `GPU` acceleration. `CPU` acceleration strongly depends on the number of site patterns in the alignment, and we note that using core genome SNPs for intra-lineage variation, performance is generally not be enhanced on `CPU`. This is because `BEAGLE` partitions the alignment into `-instances` which are then run on each `-thread`. As seen below, excessive instancing and threading on data with insufficient site patterns in fact decreases performance on `CPU`. Its advantage is that - with a penalty to runtime over `GPU` application - we can scale exploratory runs with a large number of prior configurations over clusters effectively. Ideally `GPU` clusters can be used to signficantly decrease compute time. `GPU` performance is much higher, but the number of simultaneous runs or coupled chains on a single `GPU` will slow the computation time by a factor of the number of runs or chains running on the device. Ultimately, you'd need a lot of `GPUs`

Benchmarks were conducted on the `Birth-Death Skyline Serial` model using a dataset of 575 bacterial isolates and a core-genome alignment of around 7000 SNPs - because we are using intra-lineage core-genome SNPs, there are few site patterns in the data so that instancing and threading of the partition does not provide a speed-up.

| Run **            | Minutes ***   | Minimal command                               |
| -------------     | ------------- |-----------------------------------------------|
| CPU (t: 2, i: 2)  | 38:50 min     | `beast -beagle_cpu -threads 2 -instances 2`   |
| CPU (t: 4, i: 4)  | 37:28 min     | `beast -beagle_cpu -threads 4 -instances 4`   |
| CPU (t: 8, i: 4)  | 37:31 min     | `beast -beagle_cpu -threads 8 -instances 4`   |
| CPU (t: 8, i: 8)  | 40:36 min     | `beast -beagle_cpu -threads 8 -instances 8`   |
| GPU (GTX1080-TI)  | 07:08 min     | `beast -beagle_gpu`                           |

**  `-seed 777`, time assessed at step 500k, *** per million steps on a standard MCMC

#### Prior Exploration

TBD

## Hybrid Phylogenies 

TBD

