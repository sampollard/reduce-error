#ifndef RAND_HXX
#define RAND_HXX
/* See rand.cxx for license */
void set_seed(unsigned int i1, unsigned int i2);
void get_seed(unsigned int *i1, unsigned int *i2);
double unif_rand_R(void);     // Uniform [0,1)
double unif_rand_R1(void);    // Uniform (-1,1)
double unif_rand_R1000(void); // Uniform (-1000,1000)
double subnormal_rand(void);  // My own homebrewed [0,1) with a bias towards 0, can generate subnormals
#endif
