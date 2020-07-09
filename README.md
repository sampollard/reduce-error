# Quantifying Error for MPI Reduce

## Dependencies
- [SimGrid](https://github.com/simgrid/simgrid) - preferably most recent git
  version. Also requires cmake
- [MPFR](https://www.mpfr.org/) - this is needed for Boost's C++ interface. I
  installed via spack then `module load mpfr-<tab complete>`
- Boost. This was built with Boost 1.72.0. The path should be in your
  `CPLUS_INCLUDE_PATH`. I did this by installing via spack then executing
  `module load boost-1.<tab complete>`. The important thing is you have

## Building
- To build: `make`
- To run a quick test, do `make quick`
- To run some experiments `make sim`. This outputs results in a tsv, with the
  exception of SimGrid diagnostics.
- To run just the associative tests (in serial), do `USE_MPI=0 make assoc`
- If you run MPI, then run non-mpi (or vice versa) do `make clean` inbetween.

