/* Sum up some random arrays, print their result */
#ifndef ASSOC_TEST_CXX
#define ASSOC_TEST_CXX

#include <cstdio>
#include <iostream>
#include <stdlib.h>
#include <stdbool.h>
#include <boost/multiprecision/mpfr.hpp>

#include "rand.hxx"
#include "assoc.hxx"

#define USAGE ("assoc_test <n> <iters> where\n"\
               "<n> is the number of leaves in the reduction tree\n"\
               "<iters> are the number of iterations to run\n")

#define RAND_01a() (unif_rand_R())
//#define RAND_01a() (subnormal_rand())
#define SEED 42

using namespace boost::multiprecision;

template <typename T>
T associative_sum_rand(long long n, T* A);

int main (int argc, char* argv[])
{
	/* Initialize stuff */
	int rc = 0;
	long long len, i, iters;
	double acc, rand_acc;
	/* Chapp et al. use MPFR with 4096 bits which is 1234 digits */
	mpfr_float_1000 mpfr_acc;
	double *a;
	union udouble {
		double d;
		unsigned long u;
	} pv;
	if (argc != 3) {
		rc = 1;
		fprintf(stderr, USAGE);
		return rc;
	}
	len = atoll(argv[1]);
	iters = atoll(argv[2]);
	if (len <= 0) {
		rc = 1;
		fprintf(stderr, USAGE);
		return rc;
	}
	acc = 0.;
	rand_acc = 0.;
	/* Store the random arrays */
	a = (double*) malloc(len*sizeof(double));
	std::vector<mpfr_float_1000> a_mpfr;
	a_mpfr.reserve(len);

	/* Generate some random numbers */
	set_seed(SEED, 0);
	for (i = 0; i < len; i++) {
		a[i] = RAND_01a();
		acc += a[i];
		a_mpfr.push_back(a[i]);
		mpfr_acc += a_mpfr[i];
	}

	/* Print header then different summations */
	printf("veclen\torder\tFP (decimal)\tFP (%%a)\tFP (hex)\n");
	/* MPFR */
	/* Raw hex too difficult to figure out internal data of MPFR so we use this
	 * as the place to print out the full precision of the MPFR */
	mpfr_printf("%lld\tMPFR(%d) left assoc\t%.15RNf\t%.15RNa\t%RNa\n", len,
			std::numeric_limits<mpfr_float_1000>::digits, // Precision of MPFR
			mpfr_acc, mpfr_acc, mpfr_acc);
	/* Left associative (the straightforward way to sum) */
	pv.d = acc;
	printf("%lld\tLeft assoc\t%.15f\t%a\t0x%lx\n", len, acc, acc, pv.u);
	/* Generate random association via a binary tree */
	srand(SEED);
	for (i = 0; i < iters; i++) {
		rand_acc = associative_sum_rand<double>(len, a);
		pv.d = rand_acc;
		printf("%lld\tRandom assoc\t%.15f\t%a\t0x%lx\n", len, rand_acc, rand_acc, pv.u);
	}

	/* Clean up */
	free(a);
	// done: // gotos don't play well with C++ automatic variables
	return rc;
}

/* Sum the array, using random associations. That is, this will do things like
 * (a+b)+c or a+(b+c). There are C_n different ways to associate the sum of an
 * array, where C_n is the nth Catalan number. This function has the side-effect
 * of setting the seed and calling rand() many times.
 */
template <typename T>
T associative_sum_rand(long long n, T* A)
{
	random_reduction_tree t;
	try {
		t = random_reduction_tree(2, (long) n, A);
	} catch (int e) {
		return 0.0/0.0;
	}
	return t.sum_tree();
}
#endif
