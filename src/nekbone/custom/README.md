# Running Nekbone OpenMPI Natively
Clone from git somewhere that isn't src/nekbone
1. `git clone git@github.com:CEED/Nekbone.git`
2. `cp data.rea.orig  nekpmpi SIZE /path-to-Nekbone/test/example1`
3. `cp cg.f /path-to-Nekbone/src/`
4. set `SOURCE_ROOT` in `makenek` to `/path-to-Nekbone/src`
5. edit `G="-g -mcmodel=medium"` in `makenek` (Might need `mcmodel=large` if
   you change parameters in `SIZE`)
6. `./makenek`
7. `./nekpmpi`

# Running Nekbone OpenMPI with SLURM
1. `git clone git@github.com:CEED/Nekbone.git`
2. `cp data.rea.orig SIZE /path-to-Nekbone/test/example1`
3. `cp cg.f /path-to-Nekbone/src/`
4. set `SOURCE_ROOT` in `makenek` to `/path-to-Nekbone/src`
5. edit `G="-g -mcmodel=medium"` in `makenek` (Might need `mcmodel=large` if
   you change parameters in `SIZE`)
6. Edit `./prep-nek-slurm.sh` as appropriate and
   `cp ./prep-nek-slurm.sh /path-to-Nekbone/test/example1`.  The modules I load
   will probably not be the ones you want, unless you are running on Talapas
7. `./prep-nek-slurm.sh` which builds nekbone and generates `nekbone-batch.sh`.
   Check that it looks good.
7. `sbatch nekbone-batch.sh`

# Tips
- You can run `./makenek clean` if something goes wrong
- Try to use a fortran77 compiler. For simgrid there is only `smpiff`, but this
  works.
- Make sure to load the modules in the script you call `sbatch` in.
