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

