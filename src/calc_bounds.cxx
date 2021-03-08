/* Compute theoretical error bounds */
#ifndef CALC_BOUNDS_CXX
#define CALC_BOUNDS_CXX

#include <iostream>

#include "error_semantics.hxx"

#define USAGE ("bounds <n> <lb> <ub> expr")
#define FLOAT_T double

int main (int argc, char* argv[])
{
	long long n;
	if (argc != 5) {
		std::cout << USAGE << std::endl;
		return 1;
	}

	n = atoll(argv[1]);
	lb = atoll(argv[2]);
	ub = atoll(argv[2]);
	if (len <= 0 || iters <= 0) {
		fprintf(stderr, USAGE);
		return 1;
	}

	return 0;
}
#endif
