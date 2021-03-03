#ifndef GEN_RANDOM_CXX
#define GEN_RANDOM_CXX


#include <cstdio>
#include <string>

#include "rand.hxx"

#define USAGE ("gen_random <n> <distr> where\n"\
               "<n> is the number of elements to generate\n"\
               "<distr> is the distribution to use. Choices are:\n"\
               "\trunif[0,1] runif[-1,1] runif[-1000,1000] rsubn\n")

#define FLOAT_T double

int main (int argc, char* argv[])
{
	FLOAT_T (*rand_flt)(); // Function to generate a random float
	FLOAT_T mag;
	long long len, i;
	int rc = 0;

	if (argc != 3) {
		fprintf(stderr, "Wrong argc\n%s", USAGE);
		return 1;
	}
	len = atoll(argv[1]);
	if (len <= 0) {
		fprintf(stderr, "Bad n\n%s", USAGE);
		return 1;
	}
	std::string dist = argv[2];
	rc = parse_distr<FLOAT_T>(dist, &mag, &rand_flt);
	if (rc != 0) {
		fprintf(stderr, "Unrecognized distribution:\n%s", USAGE);
		return 1;
	}
	set_seed(ASSOC_SEED, 0);
	srand(ASSOC_SEED);

	printf("%s\n",dist.c_str());
	for (i = 0; i < len; i++) {
		printf("%a\n", rand_flt());
	}
	return 0;
}

#endif
