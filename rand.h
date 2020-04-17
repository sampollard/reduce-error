#ifndef RAND
#define RAND
/* See rand.c for license */
void set_seed(unsigned int i1, unsigned int i2);
void get_seed(unsigned int *i1, unsigned int *i2);
double unif_rand_R(void);
double subnormal_rand(void);
#endif
