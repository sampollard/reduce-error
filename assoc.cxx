/* Implementation of random_reduction_tree template
 */

#include "assoc.hxx"
using namespace std;

random_reduction_tree::random_reduction_tree() { };
random_reduction_tree::~random_reduction_tree() { };

random_reduction_tree::random_reduction_tree(int k, long n, FLOAT_T* A)
	: k_(k), n_(n), A_(A)
{
	typename tree<FLOAT_T>::iterator top, root;
	top = t.begin();
	root = t.insert(top, nan(""));
	irem = n-1; /* Inner nodes remaining */
	lrem = n;   /* Leaf nodes remaining */
	changed_t v;
	if (k == 2) {
		// changed_t v = fill_balanced_binary_tree(irem, root, lrem);
		v = grow_random_binary_tree(root, lrem);
	} else {
		fprintf(stderr, "generic k-ary trees not supported yet (%d)\n", k);
		throw TREE_ERROR;
	}

	if (v.inner != irem || v.leaf != lrem) {
		fprintf(stderr, "Didn't fill tree correctly: (irem=%ld lrem=%ld, n=%ld)\n",
		        v.inner, v.leaf, n_);
		throw TREE_ERROR;
	}
}

FLOAT_T random_reduction_tree::sum_tree()
{
	return 0.0/0.0;
}

FLOAT_T random_reduction_tree::multiply_tree()
{
	return 0.0/0.0;
}

/* Make a balanced binary tree. Not random */
changed_t random_reduction_tree::fill_balanced_binary_tree(
		long irem, tree<FLOAT_T>::iterator current, long lrem)
{
	return (changed_t) {.inner = 0, .leaf = 0};
}

/* Make a random binary tree. Algorithm R from The Art of Computer
 * Programming, Volume 4, pre-fascicle 4A: A Draft of Section 7.2.1.6:
 * Generating All Trees, Donald Knuth.
 * irem: The number of inner nodes remaining.
 * t: Current node of the tree
 * lrem: Number of leaves remaining to add
 * A: Array of values to place in the tree. Removed from the right.
 * returns: The number of inner nodes and leaf nodes added in the subtree
 */
changed_t random_reduction_tree::grow_random_binary_tree(
		tree<FLOAT_T>::iterator root, long lrem)
{
	if ((2 * lrem + 1) >= RAND_MAX) {
		fprintf(stderr, "tree too big\n");
		throw TREE_ERROR;
	}
	/* Allocate an array */
	long x, k, b, n, rem;
	long *L;
	L = (long *) malloc((2*lrem + 1)*sizeof(long));
	/* Initialize (R1) */
	n = 0;
	L[0] = 0;
	while (n < lrem) { /* Done? (R2) */
		/* Advance i (R3) */
		x = rand() % (4 * n + 1);
		n++;
		b = x % 2;
		k = x / 2;
		L[2*n - b] = 2*n;
		L[2*n - 1 + b] = L[k];
		L[k] = 2*n - 1;
	}
	/* Debug */
	printf("[%ld", L[0]);
	for (rem = 1; rem < 2 * lrem + 1; rem++) {
		printf(", %ld", L[rem]);
	}
	printf("]\n");

	/* Now, to convert to C++ tree */
	free(L);
	return (changed_t) {.inner = 0, .leaf = 0};
}

/* Explicit template instantiation. Here, we see two flavors, respectively:
 * classes and class member functions */
/* template class random_reduction_tree<double>; */
/* template random_reduction_tree<double>::random_reduction_tree(int k, long n, double* A); */

