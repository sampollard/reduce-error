/* The t is for "Template" C++ file
 */

#include "assoc.hxx"
using namespace std;

random_kary_tree::random_kary_tree() { };
random_kary_tree::~random_kary_tree() { };

random_kary_tree::random_kary_tree(int k, long n, FLOAT_T* A) : k_(k), n_(n), A_(A)
{
	typename tree<FLOAT_T>::iterator top, root;
	top = t.begin();
	root = t.insert(top, nan(""));
	if (k != 2) {
		fprintf(stderr, "generic k-ary trees not supported yet (%d)\n", k);
		throw 3;
	}
	irem = n-1;
	lrem = n;
	changed_t v = fill_balanced_binary_tree(irem, root, lrem);
	// changed_t v = fill_binary_tree(irem, root, lrem);
	if (v.inner != irem || v.leaf != lrem) {
		fprintf(stderr, "Didn't fill tree correctly: (irem=%ld lrem=%ld, n=%ld)\n",
		        v.inner, v.leaf, n_);
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

changed_t random_kary_tree::fill_balanced_binary_tree(
		long irem, tree<FLOAT_T>::iterator current, long lrem)
{
	return (changed_t) {.inner = 0, .leaf = 0};
}

/* Helper, recursive function for fill_random_kary_tree */
/* irem: The number of inner nodes remaining.
 * t: Current node of the tree
 * lrem: Number of leaves remaining to add
 * A: Array of values to place in the tree. Removed from the right.
 * returns: The number of inner nodes and leaf nodes added in the subtree
 */
changed_t random_kary_tree::fill_binary_tree(
		long irem, tree<FLOAT_T>::iterator current, long lrem)
{
	int dir = 0;
	changed_t rv {.inner = 0, .leaf = 0};
	typename tree<FLOAT_T>::iterator l, r;
	/* To add another inner node we need at least 2 left in leaf budget */
	if (irem > 0 && lrem >= 2) {
		dir = rand() % 2;
	} else {
		dir = 0;
	}

	if (dir == 0) { /* I'm a leaf */
		*current = A_[lrem - 1];
		rv.leaf++;
	} else { /* I'm an inner node */
		l = t.append_child(current, nan(""));
		r = t.append_child(current, nan(""));
		rv = fill_binary_tree(irem-1, l, lrem-1); // Save at least 1 leaf
		/* Subtract how much we filled on the left side */
		rv = fill_binary_tree((n_-1)-rv.inner, r, n_-rv.leaf);
	}
	return rv;
}

/* Explicit template instantiation. Here, we see two flavors, respectively:
 * classes and class member functions */
/* template class random_kary_tree<double>; */
/* template random_kary_tree<double>::random_kary_tree(int k, long n, double* A); */

