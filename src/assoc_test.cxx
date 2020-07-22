/* Sum up some random arrays, print their result */
#ifndef ASSOC_EST_CXX
#define ASSOC_EST_CXX

#include <algorithm>
#include <cstdio>
#include <iostream>
#include <numeric>
#include <type_traits>
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
#define FLOAT_T double

/* Note: it would be more robust to use ACCUMULATOR().operator()(a,b) instead
 * of a ACC_OP b, but this doesn't work for mpfr values */
/* #define ACCUMULATOR std::multiplies<FLOAT_T> */
/* #define ACC_OP * */
#define ACCUMULATOR std::plus<FLOAT_T>
#define ACC_OP +

const bool is_sum  = std::is_same<std::plus<FLOAT_T>, ACCUMULATOR>::value;
const bool is_prod = std::is_same<std::multiplies<FLOAT_T>, ACCUMULATOR>::value;

using namespace boost::multiprecision;

template <typename T>
T associative_accumulate_rand(long long n, T* A, bool is_sum);

int main (int argc, char* argv[])
{
	/* Initialize stuff */
	int rc = 0;
	long long len, i, iters;
	FLOAT_T tmp, def_acc, rand_acc, shuf_acc;
	const FLOAT_T acc_init = is_sum ? 0. : (is_prod ? 1. : 0./0.);
	/* Chapp et al. use MPFR with 4096 bits which is 1233 digits */
	mpfr_float_1000 mpfr_acc;
	union udouble { // for type punning (to get bits of double)
		double d;
		unsigned long long u;
	} pv;
	if (argc != 3) {
		fprintf(stderr, USAGE);
		return 1;
	}
	len = atoll(argv[1]);
	iters = atoll(argv[2]);
	if (len <= 0 || iters <= 0) {
		rc = 1;
		fprintf(stderr, USAGE);
		return 1;
	}
	if (is_sum) {
		def_acc = rand_acc = shuf_acc = 0.;
		mpfr_acc = 0.;
	} else if (is_prod) {
		def_acc = rand_acc = shuf_acc = 1.;
		mpfr_acc = 1.;
	} else {
		fprintf(stderr, "Must be sum or product");
		return 1;
	}
	/* Store the random arrays */
	std::vector<FLOAT_T> def_a;
	std::vector<FLOAT_T> a_shuf;
	std::vector<mpfr_float_1000> a_mpfr;
	def_a.reserve(len);
	a_mpfr.reserve(len);
	a_shuf.reserve(len);

	/* Generate some random numbers */
	set_seed(SEED, 0);
	srand(SEED);
	for (i = 0; i < len; i++) {
		tmp = RAND_01a();

		a_mpfr.push_back(tmp);
		mpfr_acc = mpfr_acc ACC_OP a_mpfr[i];

		def_a.push_back(tmp);
		def_acc = def_acc ACC_OP tmp;

		a_shuf.push_back(tmp);
	}

	/* Print header then different summations */
	printf("veclen\torder\tFP (decimal)\tFP (%%a)\tFP (hex)\n");
	/* MPFR */
	/* Raw hex too difficult to figure out internal data of MPFR so we use FP
	 * (hex) as the place to print out the full precision of the MPFR */
	mpfr_printf("%lld\tMPFR(%d) left assoc\t%.15RNf\t%.15RNa\t%RNa\n", len,
			std::numeric_limits<mpfr_float_1000>::digits, // Precision of MPFR
			mpfr_acc, mpfr_acc, mpfr_acc);

	/* Left associative (the straightforward way to sum) */
	pv.d = def_acc;
	printf("%lld\tLeft assoc\t%.15f\t%a\t0x%llx\n", len, def_acc, def_acc, pv.u);

	for (i = 0; i < iters; i++) {
		/* Random association, don't shuffle */
		rand_acc = associative_accumulate_rand<FLOAT_T>(len, &def_a[0], is_sum);
		pv.d = rand_acc;
		printf("%lld\tRandom assoc\t%.15f\t%a\t0x%llx\n", len, rand_acc, rand_acc, pv.u);

		/* Sum a random shuffle, accumulate left-associative. */
		std::random_shuffle(a_shuf.begin(), a_shuf.end());
		shuf_acc = std::accumulate(a_shuf.begin(), a_shuf.end(), acc_init, ACCUMULATOR());
		pv.d = shuf_acc;
		printf("%lld\tShuffle l assoc\t%.15f\t%a\t0x%llx\n", len, shuf_acc, shuf_acc, pv.u);

		/* MPI-sum: random shuffle _and_ random association */
		rand_acc = associative_accumulate_rand<FLOAT_T>(len, &def_a[0], is_sum);
		pv.d = rand_acc;
		printf("%lld\tShuffle rand assoc\t%.15f\t%a\t0x%llx\n", len, shuf_acc, shuf_acc, pv.u);
	}
	return rc;
}

/* Sum the array, using random associations. hat is, this will do things like
 * (a+b)+c or a+(b+c). here are C_n different ways to associate the sum of an
 * array, where C_n is the nth Catalan number. his function has the side-effect
 * of setting the seed and calling rand() many times.
 */
template <typename T>
T associative_accumulate_rand(long long n, T* A, bool is_sum)
{
	random_reduction_tree<T> t;
	T c;
	try {
		t = random_reduction_tree<T>(2, (long) n, A);
	} catch (int e) {
		return 0.0/0.0;
	}
	if (is_sum) {
		c = t.sum_tree();
	} else {
		c = t.multiply_tree();
	}
	return c;
}
#endif
