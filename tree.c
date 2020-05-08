/* Create a binary tree for creating random associativities.  The idea here is
 * if you have a binary tree with n leaves, there are C_n different binary
 * trees. We randomly sample from these binary trees according to the following
 * process.
 *
 * 1. make an array of n
 */

#include "tree.h"

/* Provide the number of remaining non-leaf nodes and the index of your current
 * node. */
long fill_tree(long rem, long ti, node_t *tree, long n, FLOAT_T *A);
long fill_tree(long rem, long ti, node_t *tree, long n, FLOAT_T *A)
{
	static long i = 0;
	if (i == n) {
		printf("Oh bother, something went wrong in fill_tree\n");
		return 0;
	}
	/* TODO: Reset i if you're done with that tree */
	int dir = 0;
	if (rem > 0) {
		dir = rand() % (rem == 1 ? 3 : 4);
	}
	if (dir == 0) { // Left and right are leaves
		printf("Both leaves\n");
		tree[ti].l = ti*2 + 1;
		tree[tree[ti].l].f = A[i++];
		tree[ti].r = ti*2 + 2;
		tree[tree[ti].r].f = A[i++];
		return rem;
	} else if (dir == 1) { // Right is a leaf
		printf("Right leaf\n");
		tree[ti].r = ti*2 + 2;
		tree[tree[ti].r].f = A[i++];

		tree[ti].l = ti*2 + 1;
		return fill_tree(rem-1, ti*2 + 1, tree, n, A);
	} else if (dir == 2) { // Left is a leaf
		printf("Left leaf\n");
		tree[ti].l = ti*2 + 1;
		tree[tree[ti].l].f = A[i++];

		tree[ti].r = ti*2 + 2;
		return fill_tree(rem-1, ti*2 + 2, tree, n, A);
	} else {               // Neither are leaves
		printf("Neither leaves\n");
		rem = fill_tree(rem-1, ti*2 + 1, tree, n, A);
		if (rem > 0) {
			rem = fill_tree(rem-1, ti*2 + 2, tree, n, A);
		}
	}
	return rem;
}

double sample_tree_binary(FLOAT_T *A, long n)
{
	/* A binary tree with n leaves requires 2n - 1 total nodes, the non-leaf
	 * nodes represent the partial sums/products. */
	node_t *tree = (node_t *) calloc((2*n - 1), sizeof(node_t));
	long rem;
	rem = fill_tree((n-1), 0, tree, n, A);
	if (rem != 0) {
		printf("Didn't fill all inner nodes :( (%ld remaining)\n", rem);
		return 0.0;
	}
	/* Traverse the tree, filling in the partial sums. The root is the final
	 * sum */
	return 0.0/0.0;
}
