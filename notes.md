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