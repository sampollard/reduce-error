# Running Nekbone OpenMPI Natively
Clone from git somewhere that isn't src/nekbone
1. `git clone git@github.com:CEED/Nekbone.git`
2. `cp data.rea.orig  nekpmpi  README.md  SIZE /path-to-Nekbone/test/example1`
3. `cp cg.f /path-to-Nekbone/path/src/cg`
4. set `SOURCE_ROOT` in `makenek` to `/path-to-Nekbone/src`
5. edit `G="-g -mcmodel=medium"` to `makenek` (Might need `mcmodel=large` if you change parameters in `SIZE`)
6. `./makenek`
7. `./nekpmpi`

# Running Nekbone OpenMPI with SLURM
1. Complete steps 1-6 above, loading OpenMPI and GCC, preferably
2. Edit `./prep-nek-slurm.sh` as appropriate and `cp nekbone-batch.sh /path-to-Nekbone/test/example1`
3. `sbatch nekbone-batch.sh`

# Tips
- You can run `./makenek clean` if something goes wrong
- Try to use a fortran77 compiler. For simgrid there is only `smpiff`, but this works.
