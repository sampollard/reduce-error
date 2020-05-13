/* The t is for "Template" C++ file
 */

#include "assoc.hxx"
using namespace std;

random_kary_tree::random_kary_tree() { };
random_kary_tree::~random_kary_tree() { };

random_kary_tree::random_kary_tree(int k, long n, FLOAT_T* A) : k_(k), n_(n), A_(A)
{
	typename tree<FLOAT_T>::iterator root, l, r;
	root = t.begin();
	t.insert(root, nan(""));
	if (k != 2) {
		fprintf(stderr, "generic k-ary trees not supported yet (%d)\n", k);
		throw 3;
	}
	irem = n-1;
	lrem = n;
	changed_t v = fill_binary_tree(n-1, root, n, A);
	if (v.inner != 0 || v.leaf != 0) {
		fprintf(stderr, "Didn't fill tree correctly: (irem=%ld lrem=%ld, n=%ld)\n",
		        irem, lrem, n_);
		throw 3;
	}
}

FLOAT_T random_kary_tree::sum_tree()
{
	return 0.0/0.0;
}

FLOAT_T random_kary_tree::multiply_tree()
{
	return 0.0/0.0;
}

/* Helper, recursive function for fill_random_kary_tree */
/* irem: The number of inner nodes remaining.
 * t: Current node of the tree
 * lrem: Number of leaves remaining to add
 * A: Array of values to place in the tree. Removed from the right.
 * returns: The number of inner nodes and leaf nodes added in the subtree
 */
changed_t random_kary_tree::fill_binary_tree(
		long irem, tree<FLOAT_T>::iterator parent, long leaf, FLOAT_T* A)
{
	int dir = 0;
	changed_t rv;
	typename tree<FLOAT_T>::iterator l, r;
	if (irem > 0) {
		dir = rand () % (irem == 1 ? 3 : 4);
	}
	if (dir == 0) { // Left and right are leaves
		printf("Both leaves\n");
		this->t.append_child(parent, A[lrem-1]);
		this->t.append_child(parent, A[lrem-2]);
		return (changed_t) {.inner = 0, .leaf = 2};
	} else if (dir == 1) { // Right is a leaf
		printf("Right leaf\n");
		l = this->t.append_child(parent, nan(""));
		rv = fill_binary_tree(irem-1, l, lrem-1, A);
		t.append_child(parent, A[lrem-1]);
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
	return (changed_t) {.inner = 0L, .leaf = 2};
}

/* Explicit template instantiation. Here, we see two flavors, respectively:
 * classes and class member functions */
/* template class random_kary_tree<double>; */
/* template random_kary_tree<double>::random_kary_tree(int k, long n, double* A); */

