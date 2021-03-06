# Quantifying Error for MPI Reduce

## Dependencies
- [SimGrid](https://github.com/simgrid/simgrid) - preferably most recent git
  version. SimGrid requires cmake if building from source.
- Boost. The path should be in your `CPLUS_INCLUDE_PATH`. I did this by
  installing via spack then executing `module load boost-1.72<tab complete>`.
- [MPFR](https://www.mpfr.org/) - this is needed for Boost's multiprecision C++
  interface. I installed via spack then `module load mpfr-<tab complete>`

## Building
- To build: `make`
- `make quick` runs some short MPI programs for diagnostics' sake
- `make sim` runs tests for different simgrid reduction algorithms. This
  outputs results in a tsv, with the exception of SimGrid diagnostics.
- `make ompi` runs tests for different OpenMPI reduction algorithms
- `USE_MPI=0 make -j assoc` runs many random associations (must have
  `USE_MPI = 0`)
  * The output of this can be passed into R to generate plots; put the output
    into a directory, `src/analysis/experiments/assoc` then
    `cd src/analysis && Rscript assoc.R`
  * `-j` will run 4 experiments independently
- `USE_MPI=0 make gen_random` generates many random numbers. Useful for
  plotting a histogram of exotic distributions. Then use, e.g.,
  `./gen_random 50000 rsubn`
- NOTE: Do `make clean` before changing between MPI (the default) and non-mpi
  (`USE_MPI=0 make`)

## Software Versions

Versions of software:
- Boost 1.72.0
- Simgrid 3.25.1, or commit hash 4b7251c4ac80f95f82ac25ecfb3a9f618150cb11
- GCC 7.5.0 and OpenMPI 4.0.3 on the single-node
- GCC 7.3.0 and OpenMPI 2.1 on the multi-node cluster (talapas @ UOregon)
- MPFR 4.0.2

## Re-generating the tsv files

Some of the directories here were not used to generate the results, but were
used for comparison

The four that are used in `./prep-nekbone.sh`:
1. `openmpi`
2. `talapas`
3. `simgrid`
4. `smp_rsag`

This directory is used in `assoc.R`:
1. `assoc`

This is used in `height.R`:
1. `with-height`

To modify for even more experiments, you can run `prep-nekbone.sh` and add more
chunks for different directories. For example, look at `experiments/talapas`
and `experiments/onenode-allreduce`.  Those are the same file format. You can
copy that "paragraph" whose line starts with "Running on a cluster" and change
`DIR` if you want both.

You can run `./prep-nekbone.sh` to generate nekbone.tsv from the directories of
`.txt` logs

As far as regenerating experiments, this should do it:
```
# inside `nekbone` directory
./prep-nek-slurm.sh
sbatch nekbone-batch.sh

# This one will take a while.
./run-nek.sh

# inside `src`
USE_MPI=0 make gen_random
./gen_random 10000 rsubn > analysis/experiments/subn.tsv

# This one also takes a bit. Maybe an hour or two. You no longer need the
# `with-height` directory since the updated assoc binary now prints that column
# However, `height` takes longer so for large experiment numbers this is
# turned off.
USE_MPI=0 make -j assoc
```

### Modifying `run-nek.sh`
`run-nek.sh` takes a while and can be finicky. If you want to change things,
you can first comment out one of the four `make` lines to speed things up. If
you want to change the problem size, make things lower. Fortran and GCC have
memory problems and don't support `-mcmodel=large` for static arrays. You may
also need to modify `custom/SIZE` as well, which are compile-time constants for
Nekbone.

### Figures and Analysis
For figures, you should just be able to run `Rscript <file>` for each of the R
files, as long as the datasets are in the `experiments` directory. Other things
are printed which are used in the text of the paper or to justify statements.

## Generating a tar
The github repository can be found
[here](https://github.com/sampollard/reduce-error).

The tar was created using
```
tar -a -cvf datasets.tar.bz2 README.md nekbone.tsv subn.tsv openmpi talapas simgrid assoc with-height onenode-allreduce
```

Happy reproducing
-Sam

