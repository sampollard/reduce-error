/* Create a binary tree for creating random associativities.  The idea here is
 * if you have a binary tree with n leaves, there are C_n different binary
 * trees. We randomly sample from these binary trees according to the following
 * process.
 *
 * 1.
 */

#ifndef ASSOC_HXX
#define ASSOC_HXX
#include "tree.hxx"
#include <stdlib.h>
#include <cmath>

using namespace std;

/* Interface */
template <typename T>
tree<T> fill_random_kary_tree(int k, T* A, long n);

template <typename T>
T sum_tree (tree<T> t);

/* Implementation */
typedef struct chg {
	long int inner;
	long int leaf;
} changed_t;

/* Helper, recursive function for fill_random_kary_tree */
template <typename T>
changed_t fill_binary_tree(long rem, long ti, tree<T>& t, long n, T* A);

template <typename T>
tree<T> fill_random_kary_tree(long k, T* A, long n)
{
	static long i = 0;
	tree<T> t;
	typename tree<T>::iterator root, l, r;
	root = t.begin();
	t.insert(root, nan(""));
	if (k != 2) {
		fprintf(stderr, "generic k-ary trees not supported yet (%ld)\n", k);
		throw 3;
	}
	changed_t v = fill_binary_tree<T>(n-1, &t, n, A);
	if (v.inner != 0 || v.leaf != 0) {
		fprintf(stderr, "Didn't fill tree correctly: (i=%ld l=%ld, n=%ld)\n",
		        v.inner, v.leaf, n);
	}
	return t;
}

/* irem: The number of inner nodes remaining.
 * t: Current node of the tree
 * n: Number of leaves remaining to add
 * A: Array of values to place in the tree. Removed from the right.
 * returns: The number of inner nodes and leaf nodes added in the subtree
 */
template <typename T>
changed_t fill_binary_tree(long irem, tree<T>& t, long n, T* A)
{
	int dir = 0;
	changed_t rv;
	typename tree<T>::iterator l, r;
	if (irem > 0) {
		dir = rand () % (irem == 1 ? 3 : 4);
	}
	if (dir == 0) { // Left and right are leaves
		printf("Both leaves\n");
		t.append_child(A[n-1]);
		t.append_child(A[n-2]);
		return (changed_t) {.inner = 0, .leaf = 2};
	} else if (dir == 1) { // Right is a leaf
		printf("Right leaf\n");
		l = t.append_child(nan(""));
		rv = fill_tree(irem-1, l, n-1, A);
		t.append_child(A[n-1]);
		rv.leaf++;
		return rv;
	// } else if (dir == 2) { // Left is a leaf
	// 	printf("Left leaf\n");
	// 	tree[ti].l = ti*2 + 1;
	// 	tree[tree[ti].l].f = A[i++];

	// 	tree[ti].r = ti*2 + 2;
	// 	return fill_tree(rem-1, ti*2 + 2, tree, n, A);
	// } else {               // Neither are leaves
	// 	printf("Neither leaves\n");
	// 	rem = fill_tree(rem-1, ti*2 + 1, tree, n, A);
	// 	if (rem > 0) {
	// 		rem = fill_tree(rem-1, ti*2 + 2, tree, n, A);
	// 	}
	}
	return 0;
}


template <typename T>
T sum_tree (long n, tree<T> t)
{
	// t.post_order_iterator()
	return 0.0/0.0;
}

#endif
