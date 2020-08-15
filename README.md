# Quantifying Error for MPI Reduce

## Dependencies
- [SimGrid](https://github.com/simgrid/simgrid) - preferably most recent git
  version. SimGrid requires cmake if building from source.
- Boost. This was built with Boost 1.72.0. The path should be in your
  `CPLUS_INCLUDE_PATH`. I did this by installing via spack then executing
  `module load boost-1.<tab complete>`. The important thing is you have
- [MPFR](https://www.mpfr.org/) - this is needed for Boost's multiprecision C++
  interface. I installed via spack then `module load mpfr-<tab complete>`

## Building
- To build: `make`
- `make quick` runs some short MPI programs for diagnostics' sake
- `make sim` runs tests for different simgrid reduction algorithms. This
  outputs results in a tsv, with the exception of SimGrid diagnostics.
- `make ompi` runs tests for different OpenMPI reduction algorithms
- `USE_MPI=0 make -j assoc` runs many random associations (must have `USE_MPI = 0`)
  * The output of this can be passed into R to generate plots; put the output
    into a directory, `src/analysis/experiments/assoc` then
    `cd src/analysis && Rscript assoc.R`
  * `-j` will run 4 experiments independently
- `USE_MPI=0 make gen_random` generates many random numbers. Useful for
  plotting a histogram of exotic distributions. Then use, e.g.,
  `./gen_random 50000 rsubn`
- NOTE: Do `make clean` before changing between MPI (the default) and non-mpi
  (`USE_MPI=0 make`)

