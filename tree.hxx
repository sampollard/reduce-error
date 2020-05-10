#ifndef TREE
#define TREE

#ifndef FLOAT_T
#define FLOAT_T double
#endif
#ifndef FP_OP
#define FP_OP +
#endif

#include <cstdio>

typedef struct node {
	long int l;
	long int r;
	FLOAT_T f;
} node_t;

double sample_tree_binary(FLOAT_T *A, long int n);

#endif
