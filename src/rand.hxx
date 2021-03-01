#ifndef RAND_HXX
#define RAND_HXX

#include <string>

#define ASSOC_SEED 42

/* See rand.cxx for license */
void set_seed(unsigned int i1, unsigned int i2);
void get_seed(unsigned int *i1, unsigned int *i2);

double unif_rand_R(void);     // Uniform [0,1)
double unif_rand_R1(void);    // Uniform (-1,1)
double unif_rand_R1000(void); // Uniform (-1000,1000)

/* My own homebrewed [0,2) with a bias towards 0, can generate subnormals */
double subnormal_rand(void);

/* Given a string, parse it as a random number generator, returning a function
 * pointer. 0 on success, 1 on failure. */
template <typename FLOAT_T>
int parse_distr(std::string description, FLOAT_T (**distr)());

#endif
