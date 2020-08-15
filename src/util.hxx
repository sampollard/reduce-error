/* Utilities for printing and gathering results */
#ifndef UTIL_HXX
#define UTIL_HXX

#include "assoc.hxx"

template <typename T>
T associative_accumulate_rand(long long n, T* A, bool is_sum, long long *height);

template <typename T>
T associative_accumulate_rand(long long n, T* A, bool is_sum, long long *height)
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
	*height = (long long) t.height();
	return c;
}

#endif
