# Some notes on Reduce Error
## Random number generation
Consider `random` from the C `stdlib`. It returns a `long int` which is 32
bits. If you have a long int, then divide by
```
	c = 2 << (31 - 1);
```

You get numbers in the set
\[
	\{0\} \cup \{ i/c | i \in \{1,2^{31}-1\} \}
\]

For a double-precision floating point number the fractions $i/c$ will *not*
generate subnormal numbers because subnormal numbers for double-precision
are in the range $[2^{-2072}, 2^{−1022} * (1 − 2^{−52})]$.
While this does not pose many problems for true uniform random number
generation (since the floats are not uniformly distributed in $[0,1]$), these
subnormal numbers would only occur with very small probability. However, we are
interested in these rare events because of their potential for slowdown and
correctness concerns, so we wish to over-sample. Thus, a better random number
generation would be uniform in the bit ranges instead of the actual numerical
values.


To this end, the following code from the R programming language also does not
accomplish this, since it is still dividing by $2.33 x 10^{-10}$
```
static unsigned int I1=1234, I2=5678;
double unif_rand(void)
{
    I1= 36969*(I1 & 0177777) + (I1>>16);
    I2= 18000*(I2 & 0177777) + (I2>>16);
    return ((I1 << 16)^(I2 & 0177777)) * 2.328306437080797e-10; /* in [0,1) */
}
```

Look at uniform random numbers with test coverage versus

## A different way to generate random numbers in [0,1)
We have two cases:
0 in the exponent means subnormal numbers, this gives numbers of the form
[2^−149, 2^−126 x (1 - 2^-23)] for single-precision; and
[2^-1074, 2^-1022 x (1 - 2^52)] for double-precision

normal numbers with exponent equal to 1/2 - so we have numbers of the form
2^e * 1.m, where e is between [-126,-1] or [-1022,-1] so values in the range
[2^−126, 1 - 2^-23]
[2^−1022, 1 - 2^-52]
respectively.

bias = 127 for single precision, 1023 for double precision

single: e =  126 =    01111110b =  0x7E -> 2^(e-bias) = 2^-1
double: e = 1022 = 01111111110b = 0x3FE -> 2^(e-bias) = 2^-1

## Test of distribution
Just randomly picking bits of a mantissa will not generate a uniform
distribution because floating points are not uniformly distributed, unless
among a binade (numbers with the same exponent). We also miss numbers in the
ranges (1 - 2^-23, 1] and [0,2^-126], but those are not representable in
floating point.

We also test with a different generation which can make subnormal numbers
https://allendowney.com/research/rand/downey07randfloat.pdf

To test this existing (Downey) method is uniform, we use a Chi-squared test
compared with a truly uniform random distribution. We find p < 0.xxxxx

However, when measuring things like a Matrix's condition number, we may wish to
have a nonuniform distribution to artificially increase a matrix's condition number,
or increase the error, for example.

## Looking at MPI Reduce algorithm
First, you go and look at this,
```
ompi_info --param coll tuned --all | less -S
```
and look for reduce. Then, you notice the following:
```
MCA coll tuned: parameter "coll_tuned_reduce_algorithm" (current value: "ignore", data source: default, level: 5 tuner/detail, type: int)
            Which reduce algorithm is used. Can be locked down to choice of: 0 ignore, 1 linear, 2 chain, 3 pipeline, 4 binary, 5 binomial, 6
            Valid values: 0:"ignore", 1:"linear", 2:"chain", 3:"pipeline", 4:"binary", 5:"binomial", 6:"in-order_binary"
```
You then try to find out how to set this, noticing you can use environment
variables of the form `OMPI_MCA_<whatever`, read from file
`$HOME/.openmpi/mca-params.conf`, or use
```
mpirun --mca param_name param_value
```
And
[here](https://github.com/open-mpi/ompi/blob/master/ompi/mca/coll/base/coll_base_reduce.c)'s
where the file is, though I can't find 7 rabenseifner on the spack openmpi
3.1.5.

Now, I also wanna be ridiculously verbose so maybe I can do this:
```
ompi_info -a | grep verbose
```
to find
```
MCA coll base: parameter "coll_base_verbose" (current value: "error", data source: default, level: 8 dev/detail, type: int)
                          Verbosity level for the coll framework (default: 0)
                          Valid values: -1:"none", 0:"error", 10:"component", 20:"warn", 40:"info", 60:"trace", 80:"debug", 100:"max", 0 - 100
```

## Bug I ran into
`printf("%10.16f\n", )` will print different things for the same bits. Do "%a"
instead.

## Other methods
Use different distributions for pi, then move on to [Coral
benchmarks](https://asc.llnl.gov/CORAL-benchmarks/) from LLNL to see how much
differences we can find.

Softair krylov methods, linear solvers, something. Comb and see what algorithms
are most sensitive.

Another paper to look at is [this](https://ieeexplore.ieee.org/document/6831947),
which talks about MPICH reproducibility, but focuses more on performance.

There's also this idea of using a fixed-point 4300 bit accumulator to represent double-precision exactly:
[here](http://sites.utexas.edu/jdm4372/2012/02/15/is-ordered-summation-a-hard-problem-to-speed-up/)
though I don't know if there's any implementation of this.

## Onto SimGrid
I installed simgrid using
```
# Need boost, libboost-stacktrace-dev is helpful
spack install cmake%gcc@7.5.0
spack load cmake%gcc@7.5.0
git clone https://github.com/simgrid/simgrid.git
cd simgrid
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local/simgrid ..
make -j
make install
export "PATH=$PATH:$HOME/.local/simgrid/bin"
```

Now, I can't get differing results using regular running. Time to simulate.
This went about by looking first at SST from Sandia. I installed that and it's
absolutely bonkers, so I found simgrid. It wasn't too hard to install, and also I found this:
`smpirun --help-coll` which doesn't actually work. You need to do things like
```
smpirun --cfg=smpi/alltoall:pair
```
Trying to figure out logging (or other help), since `--help-logs` or as
documented doesn't give any more information.  Instead, looking at examples we
see `--log=smpi_config.thres:warning` stuff like this.

## ELPA and benchmarks
This took some good old fashioned HPC elbow grease. I used spack for a few
things, but had to download and build elpa manually. Turns out the API changed,
so I'm trying to fix that. Seems like so far only the timers changed, hopefully
that's easy.

Update: I just added
```
    double precision :: time_start, time_end, time_evp_fwd, time_evp_solve, time_evp_back
```
to the function signatures. This means the values are uninitialized and
_garbage_ but at least it builds. Another important thing is you need to
make sure elpa and eignenkernel are both built with `smpif90`, not `mpif90`.

That didn't work, so I commented them out.

Then you can run with
```
export OMP_NUM_THREADS=1
smpirun -hostfile ../hostfile-tree.txt -platform ../platform-tree.xml -np 2 \
	--cfg=smpi/host-speed:20000000 --log=smpi_config.thres:debug \
	bin/eigenkernel_app -s general_elpa1 matrix/ELSES_MATRIX_BNZ30_A.mtx matrix/ELSES_MATRIX_BNZ30_B.mtx
```
Still getting some segfaults... Giving up for now.

## Analytical measurement

## Empirircal updates.
Trying to get some logging, using `--log=coll:tuned:topo_build_tree.threshold:debug`
to get the topology stuff. Not seeing a difference was my mistake, I was
printing the wrong variable. Now I'm getting some very slight differences in
results sometimes.

I was finally able to get it to get different results.

### 5/8
Implementing the random binary trees is a little more difficult than I thought.
I forgot a few important issues, namely:
1. You can't just allocate an array for the binary tree since it's not balanced
2. There are a few more details to worry about for implementation.

However, I was able to add a custom MPI Operation, and that still resulted in
different answers.

## 5/13: Template and Linking Mishaps
[What a doozy](https://github.com/simgrid/simgrid/issues/342)

## 5/17
I figured out finally how to get the help info. You have to act as if you're
running a whole correct program. Here's an example:
```
smpirun --cfg=network/model:help -hostfile topologies/hostfile-16.txt -platform topologies/torus-2-2-4.xml -np 16 --cfg=smpi/host-speed:20000000 --cfg=smpi/reduce:ompi ./dotprod_mpi 14400 torus-2-2-4
```
Some other simgrid info: basically simgrid runs the computation on the host machine, then "scales" this to the simulated machine. I tried to add `--cfg=smpi/simulate-computation:no` because I don't care about the runtime on the new, imaginary system. However, this didn't work. I suspect it's because I never do anything with the simulation part in the first place.

However, we estimate 3 Gflops (2.40 GHz -> 3.7 Turboboost) is an underestimation. [Here](https://www.top500.org/system/179086) suggests flops/core is about 50 Gflops/s, giving 1,015 Gflops/s per CPU. This is only serial `accum += a * b` though, so we use a much lower number.

I added duplicate entries for hostfiles just to simplify the makefile and make things _slightly_ more modular.

## 5/22
If you run
```
smpirun -hostfile topologies/hostfile-torus-2-4-9.txt -platform topologies/torus-2-4-9.xml -np 72 --cfg=smpi/host-speed:3000000000 --cfg=smpi/reduce:mvapich2_knomial --log=root.thres:critical ./dotprod_mpi 720 torus-2-4-9 mvapich2_knomial
```

You get different answers for using a custom MPI operation, noncommutative sum.

# Euler2d

`pkestene/euler_kokkos` didn't work, trying the non-mpi version:
```
# OBSOLETE
spack load openmpi@4.0.3
git clone https://github.com/pkestene/euler2d_kokkos
cd euler2d_kokkos
git submodule init
git submodule update
mkdir -p build
cd build
cmake -DUSE_MPI=ON -DKokkos_ENABLE_HWLOC=ON -DKokkos_ENABLE_OPENMP=OFF ..
make -j 4
```

Got the non-mpi version to run. From the paper,

> using a fixed time step of ∆t ≈ 2.8e-4,

but we don't know how long the simulation runs for :facepalm:
10,000 timesteps for 3 seconds is on the same order of magnitude.

Submitted [bug](https://github.com/pkestene/euler_kokkos/issues/1)
for `euler_kokkos`, got it to build via:
```
# OBSOLETE
spack load openmpi@4.0.3
git clone https://github.com/pkestene/euler2d_kokkos
cd euler_kokkos
git submodule init
git submodule update
mkdir -p build
cd build
cmake -DUSE_MPI=ON -DKokkos_ENABLE_HWLOC=ON -DKokkos_ENABLE_OPENMP=OFF -DMPI_CXX=smpicxx ..
make -j 4
```
which compiled! Now to get it to run, do
```
mpirun -np 6 src/euler_kokkos test/io/test_io_2d.ini
```
(`-np = my * mz * mz` in the `.ini`)

Now, to get to build with simgrid we have to learn cmake ):
```
cp ../simgrid/FindSimGrid.cmake cmake
spack unload openmpi@4.0.3
mkdir -p sbuild
cd sbuild
SimGrid_PATH=$HOME/.local/simgrid cmake -DUSE_SIMGRID=ON -DUSE_MPI=ON -DKokkos_ENABLE_HWLOC=OFF -DKokkos_ENABLE_OPENMP=OFF \
	-DCMAKE_LIBRARY_PATH=$HOME/.local/simgrid/lib \
	-DMPI_CXX_COMPILER=smpicxx -DMPI_C_COMPILER=smpicc ..
make -j4
```
Then run with
```
smpirun -np 6 \
	-hostfile $HOME/mpi-error/topologies/hostfile-torus-2-4-9.txt -platform $HOME/mpi-error/topologies/torus-2-4-9.xml \
	--cfg=smpi/host-speed:20000000 --log=smpi_config.thres:debug \
	src/euler_kokkos test/io/test_io_2d.ini
```
which fails with
```
Execution failed with code 134.
and
bad entry point
```
Maybe I need the LD library path stuff?

# Apps To Try
Petsc or TAU
Driven cavity - good example. Has MPI reduces and such. Driven cavity in petsc
examples (snes). Also linear solvers.

Chapter on just saying limitations - e.g. compcert can't do this optimization or something.
Can a NaN become a non-nan?

# Simgrid & Petsc

- Look [here](https://www.mcs.anl.gov/petsc/documentation/installation.html) for resources
- `--with-mpi-dir` at first I thought was only for MPICH but appears to not be true
- You don't want the compilers to be `smpi` ones.
- tried `./configure --with-mpi-dir=$HOME/.local/simgrid/bin --with-mpiexec=smpirun --with-cc=gcc --with-fc=gfortran --with-cxx=g++`
- Fortran `smpif90` causes problems, so we're trying to not use that at all
- Tried building with `export CFLAGS='SMPI_NO_OVERRIDE_MALLOC=1'` but that didn't help.
- Getting some weird error with:
  ```
   /home/users/spollard/.local/simgrid/include/smpi/smpi_helpers.h:36:48: error: expected declaration specifiers or ‘...’ before ‘(’ token
   #define malloc(x) smpi_shared_malloc_intercept((x), __FILE__, __LINE__)
  ```
  and some other stuff.
- (also tried this: `--with-mpiexec='smpirun -hostfile /home/users/spollard/mpi-error/topologies/hostfile-fattree-16.txt -platform /home/users/spollard/mpi-error/topologies/fattree-16.xml --cfg=smpi/host-speed:20000000' \`
- Try `SMPI_PRETEND_CC=1 ./configure ... --with-cflags='SMPI_NO_OVERRIDE_MALLOC=1'` - not quite enough
- Triied
 ```
 # DOES NOT WORK
 unset PETSC_DIR
 export SMPI_PRETEND_CC=1
 ./configure --prefix=$HOME/.local/petsc \
 	--LDFLAGS="-L$HOME/.local/simgrid/lib -Wl,-rpath=$HOME/.local/simgrid/lib" \
 	--with-mpi-lib=$HOME/.local/simgrid/lib/libsimgrid.so \
 	--with-mpi-include=$HOME/.local/simgrid/include/:$HOME/.local/simgrid/include/smpi \
 	--with-cflags='SMPI_NO_OVERRIDE_MALLOC=1' \
 	--with-fortran-bindings=0 \
 	--with-cc=smpicc --with-cxx=smpicxx --with-fc=gfortran
 ```
after a chat on the `#simgrid` debian IRC. Then I built with

```
# This didn't work
unset SMPI_PRETEND_CC
make PETSC_DIR=/home/users/spollard/mpi-error/petsc PETSC_ARCH=arch-linux-c-debug all
make PETSC_DIR=/home/users/spollard/mpi-error/petsc PETSC_ARCH=arch-linux-c-debug install
```

Then
```
# This didn't work
export PETSC_DIR=$HOME/.local/petsc
cd $PETSC_DIR/share/petsc/examples/src/ts/tutorials
make ex26
smpirun -np 16 \
	-hostfile $HOME/mpi-error/topologies/hostfile-fattree-16.txt -platform $HOME/mpi-error/topologies/fattree-16.xml \
	--cfg=smpi/host-speed:20000000 --log=smpi_config.thres:debug \
	./ex26
```

But this gets the error
```
[node-0.hpcl.cs.uoregon.edu:0:(1) 0.000000] /home/users/spollard/mpi-error/simgrid/src/smpi/internals/smpi_global.cpp:501: [root/CRITICAL] Could not resolve entry point
Backtrace (displayed in actor 0):
 0# simgrid::xbt::Backtrace::Backtrace() at ./src/xbt/backtrace.cpp:68
 1# xbt_backtrace_display_current at ./src/xbt/backtrace.cpp:33
 2# operator() at ./src/smpi/internals/smpi_global.cpp:501
 3# smx_ctx_wrapper at ./src/kernel/context/ContextSwapped.cpp:48

./ex26 --cfg=smpi/privatization:1 --cfg=surf/precision:1e-9 --cfg=network/model:SMPI --cfg=smpi/host-speed:20000000 --log=smpi_config.thres:debug /home/users/spollard/mpi-error/topologies/fattree-16.xml smpitmp-appjBGHMD
Execution failed with code 134.
```

Chatting with the Simgrid people. They made some fixes, then said: (I had to
add `--with-fortran-bindings=0`)

```
 # This Works!
unset PETSC_DIR SMPI_PRETEND_CC
SMPI_PRETEND_CC=1 ./configure --prefix=$HOME/.local/petsc \
	--with-cc=smpicc --with-fc=smpif90 --with-cxx=smpicxx --CFLAGS="-DSMPI_NO_OVERRIDE_MALLOC=1" \
	--with-fortran-bindings=0
SMPI_NO_UNDEFINED_CHECK=1 make PETSC_DIR=/home/users/spollard/mpi-error/petsc PETSC_ARCH=arch-linux-c-debug all
SMPI_NO_UNDEFINED_CHECK=1 make PETSC_DIR=/home/users/spollard/mpi-error/petsc PETSC_ARCH=arch-linux-c-debug install
```

Now, the unit tests will fail (because `smpirun` can't be dropped in for
`mpirun`, it needs host and topology files). The only thing I was able to
get working was ex26 with 1 processor. That is:

## Simgrid Troubleshooting
`error code 134` and `could not resolve entry point` - This is probably a
miscompilation issue. You can check that you are using `smpicc` instead of
`mpicc`.

If you see things like `MPI_C_HEADER_DIR` pointing to some other mpi header,
then you need to fix this. If the script has `./configure`, you can just set
the `LD_LIBRARY_PATH` and and include path accordingly and it should pick
things up.

Another potential issue is the Cmake of your project might have found some
other MPI implementation and tried to link to it. You can check this via

```
cmake <cmake flags> -LA .. | grep '^MPI_'
```


```
[0]PETSC ERROR: --------------------- Error Message --------------------------------------------------------------
[0]PETSC ERROR: Object is in wrong state
[0]PETSC ERROR: Cannot call this routine more than once, it can only be called in PetscInitialize()
[0]PETSC ERROR: See https://www.mcs.anl.gov/petsc/documentation/faq.html for trouble shooting.
[0]PETSC ERROR: Petsc Release Version 3.13.2, unknown
[0]PETSC ERROR: ./ex1 on a  named artemis by spollard Wed Dec 31 16:00:00 1969
[0]PETSC ERROR: Configure options --prefix=/home/users/spollard/.local/petsc --with-cc=smpicc --with-fc=smpif90 --with-cxx=smpicxx --CFLAGS=-DSMPI_NO_OVERRIDE_MALLOC=1 --with-fortran-bindings=0
[0]PETSC ERROR: #43 PetscMallocSetDebug() line 889 in /home/users/spollard/mpi-error/petsc/src/sys/memory/mtr.c
[0]PETSC ERROR: #44 PetscOptionsCheckInitial_Private() line 419 in /home/users/spollard/mpi-error/petsc/src/sys/objects/init.c
[0]PETSC ERROR: #45 PetscInitialize() line 1004 in /home/users/spollard/mpi-error/petsc/src/sys/objects/pinit.c
[node-15.hpcl.cs.uoregon.edu:15:(16) 0.002423] /home/users/spollard/mpi-error/simgrid/src/smpi/internals/smpi_global.cpp:334: [smpi_kernel/WARNING] SMPI process did not return 0. Return value : 73
[0.002423] /home/users/spollard/mpi-error/simgrid/src/simix/smx_global.cpp:554: [simix_kernel/CRITICAL] Oops! Deadlock or code not perfectly clean.
[0.002423] [simix_kernel/INFO] 1 actors are still running, waiting for something.
[0.002423] [simix_kernel/INFO] Legend of the following listing: "Actor <pid> (<name>@<host>): <status>"
[0.002423] [simix_kernel/INFO] Actor 1 (0@node-0.hpcl.cs.uoregon.edu)
[0.002423] [smpi/INFO] Stalling SMPI instance: smpirun. Do all your MPI ranks call MPI_Finalize()?
./ex1 --cfg=smpi/privatization:1 --cfg=surf/precision:1e-9 --cfg=network/model:SMPI --cfg=smpi/host-speed:20000000 --log=smpi_config.thres:debug /home/users/spollard/mpi-error/topologies/fattree-16.xml smpitmp-appWI5fQZ
Execution failed with code 73.
```

From degomme:
>  yes I would advise to try another one in the meantime, as petsc is a huge
>  beast, and relies on quite rarely used MPI calls that are not our strength
>  .. But it's a nice way for us to debug smpi.

But, I can get a working version with 1 processor
```
export PETSC_DIR=$HOME/.local/petsc
cd $PETSC_DIR/share/petsc/examples/src/ts/tutorials
make ex26
smpirun -np 1 \
	-hostfile $HOME/mpi-error/topologies/hostfile-fattree-16.txt -platform $HOME/mpi-error/topologies/fattree-16.xml \
	--cfg=smpi/host-speed:20000000 --log=smpi_config.thres:debug \
	./ex26
```

## Trying different Petsc examples
```
export PETSC_DIR=$HOME/.local/petsc
cd $PETSC_DIR/share/petsc/examples/src/snes/tutorials
make ex12
smpirun -np 16 \
	-hostfile $HOME/mpi-error/topologies/hostfile-fattree-16.txt -platform $HOME/mpi-error/topologies/fattree-16.xml \
	--cfg=smpi/host-speed:20000000 --log=smpi_config.thres:debug \
	./ex12
```


## Back to Sampling
### 6/26
Reading Volume 4, fascicle 4a, you would think Knuth is getting paid whatever
the opposite of "per word" is. It took me a very long time to understand what
was going on because of the weird GOTO algorithm syntax as well as no
explanation for what k means. But whatever, I eventually figured it out.  Some
examples of random trees:
```
n = 5: [1, 2, 7, 5, 4, 6, 0, 8, 3]
n = 4: [1, 2, 3, 5, 4, 6, 0]
```

### 7/3
Finally got some MPI reduction working. The trick was to look for nan's in the tree;
if you're inside a nan, recurse down and try to fill in accumlated values.

### MPFR
Jul 8, 2020

The good news with MPFR is its C interface works with C++ too.  Not too bad to
get working, as long as I get the right includes. Here's what I need on
artemis, e.g.
```
module load boost-1.72.0-gcc-7.5.0-q725eoa
spack load mpfr@4.0.2
USE_MPI=0 make -s assoc > assoc.tsv
```
Output changed a little. To get things to align, do `tabs -20` or something in the terminal.

### Next Steps
- Template the assoc class. This is because I want float, double, MPFR, as well
  as maybe some kind of nonconforming IEEE formats. Update: wasn't too bad to
  template! Just gotta sprinkle in typenames everywhere and be more careful with
  what the typechecker can guess (it can't guess allocators)
- Add in product, not just sum reduction.
- Data analysis

### MPFR nastiness
They print differently. See [my stack overflow question](https://stackoverflow.com/questions/62828959/why-is-mpfr-printf-different-than-printf-for-hex-float-a-conversion-specifier)

I got some _really_ weird results when I did accumulate with * and I
initialized the result to 0. Should be 0 x .... = 0, but it wasn't in all cases.
Also seems to happen when i intialize the accumulator to 1.0 too!

### 7/21 - First plots
Use uniform [0,1) generator.
```
spack load mpfr@4.0.2
USE_MPI=0 make -s assoc
```

GGplot is pretty good at figuring out plot boundaries but sometimes you need things like
` ymin = min(error)*1.2, ymax = max(error)*1.2)` in aes

### Some R melt stuff
At first I measured two differences, but that just gets confusing. Better to show the bars.
```
df_la$error_mpfr <- mpfr_1000 - df_la$fp_decimal
df_la$error_la <- canonical - df_la$fp_decimal
df_er <- melt(df_la[c("order","error_mpfr","error_la")], variable.name = "error_type")
 # Then later I had
  geom_point(aes(color = factor(error_type)))
```

### Sum stuff

Also I added in the "evil" mpi-style sum which shuffles and randomly associates
Get it with
`scp artemis.cs.uoregon.edu:/home/users/spollard/mpi-error/src/assoc.tsv experiments/assoc-runif.tsv`
Then
`Rscript assoc.R`

Look into `library(egg)` [for alignment with legends](https://stackoverflow.com/questions/16255579/how-can-i-make-consistent-width-plots-in-ggplot-with-legends)

Apparently ggsave
[(it's an R problem as of 2015)](https://github.com/tidyverse/ggplot2/issues/268)
doesn't update timestamps? Delete then rewrite... that's dumb :(

## Running Experiments
Getting lots of plots. Do this
```
spack load mpfr@4.0.2
USE_MPI=0 make -j assoc
```
Should take about 2 hours??? Some other numbers:
assoc_big takes about 50 hours
assoc_deep takes about 30 minutes

### Combinatorics
Number of ways to reduce a commutative, nonassociative operator:
Not quite [this](https://en.wikipedia.org/wiki/Wedderburn%E2%80%93Etherington_number)
Not quote [this](https://oeis.org/A083563)

[It's this one!](https://oeis.org/A001147) - double factorial for odd numbers.

n  n!!            rho(n)           n!/2         C(n-1)
0  1               1              1             1
1  1               1              1             1
2  3               1              1             1
3  15              3              3             2
4  105             15             12            5
5  945             105            60            14
6  10395           945            360           42
7  135135          10395          2520          132
8  2027025         135135         20160         429
9  34459425        2027025        181440        1430
10 654729075       34459425       1814400       4862
11 13749310575     654729075      239500800     16796
12 316234143225    13749310575    3113510400    58786
13 7905853580625   316234143225   43589145600   208012

## Plotting or: Lots of time spent
A cool trick to get `DBL_MIN` for a system `gcc -dM -E - < /dev/null | less`

Want to figure out what the potential max error is, given range of values and # summed.

### Some Colorscheme stuff
Problem is it seems to only be light blues...
```
palette <- scale_color_brewer("Dark2")$palette(5)
d <- data.frame(x1=c(1,3,1,5,4), x2=c(2,4,3,6,6), y1=c(1,1,4,1,3), y2=c(2,2,5,3,5), t=palette, r=c(1,2,3,4,5))
ggplot() + 
	scale_x_continuous(name="x") + 
	scale_y_continuous(name="y") +
	geom_rect(data=d, mapping=aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2, fill=t), color="black", alpha=0.7) +
	geom_text(data=d, aes(x=x1+(x2-x1)/2, y=y1+(y2-y1)/2, label=r), size=4)
```

I like the idea of this code but it causes more pain than its worth
```
pidx <- 1
for (x in c("ra", "sla", "sra")) {
	cdf <- get(x)
	pd <- ggplot_build(p) # Gets all the computed data from ggplot
	p_count <- pd$data[[pidx]]$count
	print(mean(cdf$error_mpfr))
	geom_vline(
		aes(xintercept = mean(cdf$error_mpfr)),
			color = palette[pidx], linetype = "solid", alpha=0.7)
	pidx <- pidx + 1
}
```

### Plotting ideas

Another weird thing for plotting is: if you want things in the legend, you have
to shove some stuff into the `aes` so it gets picked up by the guide. Building
it on your own is not the play, you need to match the strings together from the
`geom_hist` or `geom_vline` and if tweaking is required, you do that in
`scale_color_manual`

Plot looks bad if I add `guides(linetype = guide_legend(override.aes = list(size = 1)))`
If I wanted to change orientation of key legend, that's not easy :(
[nastiness](https://stackoverflow.com/questions/42954248/how-to-change-the-orientation-of-the-key-of-a-legend-in-ggplot)

7/26 -
Here I think is a [better solution](https://stackoverflow.com/questions/34186081/vline-legends-not-showing-on-geom-histogram-type-plot)

A realization I had (finally). When you put things in `aes`, it gives you a
_mapping_ from data to what it means, aesthetically. This is not the same as
describing the aesthetics itself, and this is a big part of the modularity of
ggplot. For example, I was putting
```
geom_vline(data = vlines, show.legend = TRUE,
        aes(xintercept = Value, color = Color, linetype = Linetype))
```
because, well, I put the colors right there! But instead, it's saying the color is determined
by the _data_ in that part of the data frame. In my case, it was really the
names (or values, there's 1-1 in my case) that I want to split the color by. So
instead it should be
```
geom_vline(data = vlines, show.legend = TRUE,
        aes(xintercept = Value, color = Statistic, linetype = Linetype))
```
where `Statistic` is something like `c("mean", "median",)`, or whatever. Similarly, if you
don't put the specification inside of `aes` things won't get "picked up"
outside, like if I were to put "linetype" outside of `geom_vline`, it will say
"ok linetype is just here, has nothing to do with the declaration of what the
data means."

Do I want this? `legend.key.size = unit(1.1, 'lines'))`

This didn't work:
```
# Changing vertical gap between legend entries. What a doozy.
# https://stackoverflow.com/questions/11366964/is-there-a-way-to-change-the-spacing-between-legend-items-in-ggplot2
# @clauswilke
draw_key_polygon3 <- function(data, params, size) {
  lwd <- min(data$size, min(size) / 4)
  grid::rectGrob(
    width = grid::unit(0.6, "npc"),
    height = grid::unit(0.6, "npc"),
    gp = grid::gpar(
      col = data$colour,
      fill = alpha(data$fill, data$alpha),
      lty = data$linetype,
      lwd = lwd * .pt,
      linejoin = "mitre"
    ))
}
# register new key drawing function, 
# the effect is global & persistent throughout the R session
#TODO: Need Geom<something> cause I don't have a bar graph
GeomBar$draw_key = draw_key_polygon3
```

Tough: making a string, then going to an expression,
you _have_ to do `Labels <- expr_vec(vlines$Statistic)`,
or else ggplot will not pick up that the rvalues are the same.

## 7/29 - Trying to get more statistics
Using geometric mean, absolute error not particularly helpful.
Some reduction orders are _almost_ perfect, should probably note those
in a table or something?

Also had trouble working with Rmpfr because I couldn't install gmp in R.

Might email or make an issue [here](https://cran.r-project.org/web/packages/gmp/index.html)

I also want to look into Downey's sampling stuff. That seems interesting, like
it would get better coverage

## Rmpfr Fever Dream
I had to download gmp for R
[here](https://cran.r-project.org/src/contrib/gmp_0.6-0.tar.gz),
unpack it, edit configure.ac to include this
```
if test /opt/local != "$exec_prefix" -a /opt/local != "$prefix" ; then
  CPPFLAGS="$CPPFLAGS -I/opt/local/include"
  LDFLAGS="$LDFLAGS -L/opt/local/lib"
fi
```
then run `autoreconf -i`, then run
`install.packages("~/local/gmp/", repos = NULL, type="source")`
(that's where I unzipped the gmp tarball), then
`install.packages(Rmpfr)`. Whew.

## More Distributions
Probably what I'll do is look at a buch, then compare, e.g.,
absolute error (might be tough to scale accordingly) and then
relative error across (0,1) then (-1000,1000).

Gotta be careful with relative error since floating point might
mess it up at the deltas.

### 7/31
Maybe this `vlines` and `hist_style` thing is not so good. It's fine
for consistency across plots but it makes things really difficult
to add, say, a third histogram. Oh my, did I code this up poorly. This
should all be in one dataframe and `melt`ed.

I want to look into the work from 1993 but with just different associativity,
not shuffling. But that seems not doable in time.


## Nekbone
### 8/3
- `wget https://asc.llnl.gov/CORAL-benchmarks/Science/nekbone-2.3.4.tar.gz`
- Edit `test/example1/nekpmpi` to have this line
 ```
 smpirun -hostfile hostfile-fattree-16.txt -platform fattree-16.xml \
     --cfg=smpi/host-speed:3000000000f \
     -np $2 ./nekbone $1 > $1.log.$2
 ```
- Add `test/example1/makenek` so `F77=smpiff` and `CC=smpicc` and
 ```
 cp ../../../topologies/fattree-16.xml .
 cp ../../../topologies/hostfile-fattree-16.txt .
 ```
- `./makenek 1`
- `./nekpmpi 1 4` : run nekbone on experiment 1 with 4 processors
- Somehow, it worked! ha. Anyway, next need to edit to print higher precision
- Change `cg.f` line 147 to `    6    format('cg:',i4,1p4e27.20)`
- So it seems like the results are the same for each run :( Maybe try different
  simgrid algos?
- Should try slightly updated version https://asc.llnl.gov/coral-2-benchmarks/
- Huge annoyance - the code was absolutely refusing to run anything other than
  512 elements/process. Turns out the solution was to change not `SIZE` but
  `data.rea`. Sigh.
- Okay, so the cryptic `iel0,ielN,ielD` is element 'start, stop, by" for a `DO`
  loop. What this means is you run the experiment OVER AND OVER if you don't
  put, e.g., `128 128 1  = iel0,ielN,ielD` (because if you do `128 256 1` then it
  will run 128 times using different counts of elements. I think.

### Nekbone 3.1: Revolutions
- Do [this one](https://github.com/Nek5000/Nekbone) instead. It also has a much
  better user guide pdf
- [Here](https://asc.llnl.gov/coral-2-benchmarks/downloads/Nekbone_Summary_2_3_6.pdf)
  is an older pdf, might be useful but right now stick with the one in the
  github repo.
- `git clone git@github.com:Nek5000/Nekbone.git`
- The numbering scheme is confusing. Nekbone 3.1 corresponds to v0.17 on Github.

## Simgrid (again)
### Toplogies
Looking [here](https://simgrid.org/doc/latest/Tutorial_MPI_Applications.html)
Supposing I want to add a dragonfly example:
`topo_parameters=#groups;#chassis;#routers;#nodes` - see dragonfly-72.xml
I can go up to 288 with my examples, easily. Would be nice to add bigger process counts,
but oh well.

### Allreduce algorithms
With `smp_rsag_lr`, there is an error that says `MPI_allreduce_lr use default MPI_allreduce`
which happens when `rcount < size` (I think rcount is receiver count) (when
communication size is smaller than number of process).

Also `allreduce-lr.cpp:41: [smpi_colls/WARNING] MPI_allreduce_lr use default MPI_allreduce.`


## Next steps
1. ✓ Do runiform[-1,1]
2. ✓ (low priority) Kahan Summation
3. ✓ (low priority) Repro BLAS (at least cite)
3. ✓ Do the nearly-subnormal generation
4.  Cite that interesting not-quite paper on generating FP numbers (Generating
  Pseudo-random Floating-Point Values, Allen B. Downey)  maybe even implement
  it.  Weird, this one's from
  [Computational Science](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7302591/)
5. ✓ Different topologies
6. ✓ Cite https://oeis.org/A001147
7. ✓ Multiple histograms
8. ✓ Make the "nearly identical" plot so it looks uniform
9. ✓ Investigate the following: Is there a fundamental tradeoff between the
  height of the reduction tree and the error? e.g. left-associative is the
  most "unbalanced" in a sense - we also find the error is pretty high.

  Answer: Kind of? There is a positive correlation (except for unif(-1,1) which
  is slightly negative. Further work necessary.
10. ✗ Plot stuff from `dotprod.tsv`
11. ✗ Run simgrid with the simple sum program for different allreduce algorithms
12. Explain what we get from each of figs 3,4,5
   - ✓ 3: Forcing left associativity can have worse error
   - 4: When generating random sums, the associativity matters more than
        ordering (makes sense since FP addition is commutative). This also means
        that `commute = true` should not make much difference with MPI custom operations.
   - ✓ 5: U(-1,1) has the worst error, probably because more catastrophic cancellation happens
13. ✓ Put averages in table for figs 3,4,5

## Paper writing
### 8/12/20
- Hypothesis that different simgrid reductions on nekbone will cause different
  results is not false, but nekbone+simgrid is pretty reproducible. I don't
  know why. It seems to be more robust that I expected.

### Final Paper Steps: Aug 16-17
- Talapas is a pain. You have to load the modules in sbatch if you didn't load
  them in the interactive shell.
- `assoc.R` needs some improvement with how it handles the bin counting. It's
  probably just better to used a fixed count in most cases.
- SimGrid results are weird. The later trials all have the same result. Maybe
  it's because of how I built it? Earlier trials were recompiling more
  frequently. In the interest of time I didn't do that for trials > about 18.
  Worth looking into in the future. Maybe it's different compilation flags too?
- Just for grins, I want to see if we assume subn is exponential (with 355 as
  its factor, IIRC when we did expfit). I want to see how close the error is
  with Robertazzi.

## Vec-E and Mat-E: Error built-in
The idea here is to have a class that has three main elements:
1. dimension
2. numerical data (double or float, real or complex)
3. error bound, as MPFR

This could be generalized to vectors, matrices, and higher-order tensors. As operations
are done on them (i.e. vec + vec) the error bounds changes. To support this, things
like maximum magnitude may also be updated.

## Looking at Inverse Square Root (rsqrt) for 32-bit
```
import numpy as np
y = np.array([.0001,1,.0001,1,.0001,1,.0001,1,.0001,1], dtype=np.single)
yd = np.array([.0001,1,.0001,1,.0001,1,.0001,1,.0001,1], dtype=np.double)
1.0/np.sqrt(np.sum(y * y))
1.0/np.sqrt(np.sum(yd * yd))
x = np.array([0.0001]*10, dtype=np.single)
xd = np.array([0.0001]*10, dtype=np.double)
1.0/np.sqrt(np.sum(x * x))
1.0/np.sqrt(np.sum(xd * xd))
```
