# Some notes on HPC
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
>  yes I would advise to try another one in the meantime, as petsc is a huge beast, and relies on quite rarely used MPI calls that are not our strength .. But it's a nice way for us to debug smpi.

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


## Back to Algorithmic Sampling

