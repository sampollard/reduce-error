/*
 *  Mathlib : A C Library of Special Functions
 *  Copyright (C) 2000, 2003  The R Core Team
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, a copy is available at
 *  https://www.R-project.org/Licenses/
 *
 */

/* A version of Marsaglia-MultiCarry */

static unsigned int I1=1234, I2=5678;

void set_seed(unsigned int i1, unsigned int i2)
{
    I1 = i1; I2 = i2;
}

void get_seed(unsigned int *i1, unsigned int *i2)
{
    *i1 = I1; *i2 = I2;
}


double unif_rand_R(void)
{
    I1= 36969*(I1 & 0177777) + (I1>>16);
    I2= 18000*(I2 & 0177777) + (I2>>16);
    return ((I1 << 16)^(I2 & 0177777)) * 2.328306437080797e-10; /* in [0,1) */
}

typedef union Double Double;
union Double {
    double f;
    unsigned long long d;
};

double subnormal_rand(void)
{
    I1= 36969*(I1 & 0177777) + (I1>>16);
    I2= 18000*(I2 & 0177777) + (I2>>16);

	Double x;
	long long unsigned i1 = (unsigned long long) I1;
	long long unsigned i2 = (unsigned long long) I2;

	x.d = (i1 << 32) ^ i2;
	/* Clear sign and most significant exponent digit so that sign is positive
	 * and the exponent is < 0. This method will actually be able to generate
	 * subnormal numbers, though it is not uniformly distributed. */
	x.d = x.d & ~(3ULL << 62);
	return x.f;
}
