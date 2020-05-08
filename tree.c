/* Create a binary tree for creating random associativities.  The idea here is
 * if you have a binary tree with n leaves, there are C_n different binary
 * trees. We randomly sample from these binary trees according to the following
 * process.
 *
 * 1. make an array of n
 */

#include "tree.h"

double sample_tree_binary(FLOAT_T *A, long int n)
{
	/* A binary tree with n leaves requires 2n - 1 total nodes, the non-leaf
	 * nodes represent the partial sums/products. */
	node_t *tree = (node_t *) calloc((2*n - 1), sizeof(node_t));
	long int *stack = (long int *) calloc((n-1), sizeof(long int));
	int dir;
	long int cnt, i, sp, ele;
	cnt = 0;
	/* Initialize stack by pushing left and right of root */
	stack[0] = 1;
	stack[1] = 2;
	sp = 1;
	while (cnt < n) {
//		if (stack empty and >2 elements left to add)

		ele = stack[sp];
		stack[sp--] = 0;

		/* Left */
		dir = rand() % 2;
		if (dir == 0) {         // Left is a leaf
			tree[tree[i].l].f = A[cnt];
			tree[tree[i].r].r = i * 2 + 1;
			i = i * 2 + 1;
		} else {                // Left is not a leaf
			stack[sp++] = i * 2 + 1;
		}

		if (dir == 1) {  // Right is a leaf
			tree[tree[i].r].f = A[cnt];
			tree[tree[i].l].r = i * 2 + 2;
			i = i * 2 + 2;
		} else if (dir == 2) { // Neither are leaves
			// push..
		} else {               // Both are leaves
			; // something
		}
	}
	/* Our off-by-one correction: The last tree is both leaf nodes. */
	if (n > 1) {
		;
	}
	/* Traverse the tree, filling in the partial sums. The root is the final
	 * sum */
	return 0.0/0.0;
}
