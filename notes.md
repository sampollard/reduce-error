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
