#ifndef GEN_RANDOM_CXX
#define GEN_RANDOM_CXX


#include <cstdio>
#include <string>

#include "rand.hxx"

#define USAGE ("gen_random <n> <distr> where\n"\
               "<n> is the number of elements to generate\n"\
               "<distr> is the distribution to use. Choices are:\n"\
               "\trunif[0,1] runif[-1,1] runif[-1000,1000] rsubn\n")

int main (int argc, char* argv[])
{
	double (*rand_flt)(); // Function to generate a random float
	long long len, i;

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
	if (dist == "runif[0,1]") {
		rand_flt = &unif_rand_R;
	} else if (dist == "runif[-1,1]") {
		rand_flt = &unif_rand_R1;
	} else if (dist == "runif[-1000,1000]") {
		rand_flt = &unif_rand_R1000;
	} else if (dist == "rsubn") {
		rand_flt = &subnormal_rand;
	} else {
		fprintf(stderr, "Unrecognized distribution:\n%s",USAGE);
		return 1;
	}
	set_seed(SEED, 0);
	srand(SEED);

	printf("%s\n",dist.c_str());
	for (i = 0; i < len; i++) {
		printf("%a\n", rand_flt());
	}
	return 0;
}

#endif
