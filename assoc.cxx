/* Implementation of random_reduction_tree.
 * To add a new instance, add explicitly at the bottom of this file
 */
#ifndef ASSOC_CXX
#define ASSOC_CXX

#include "assoc.hxx"

#include <boost/multiprecision/mpfr.hpp>

using namespace std;

template <class FLOAT_T, class ALLOC>
random_reduction_tree<FLOAT_T, ALLOC>::random_reduction_tree() { };
template <class FLOAT_T, class ALLOC>
random_reduction_tree<FLOAT_T, ALLOC>::~random_reduction_tree() { };

template <class FLOAT_T, class ALLOC>
random_reduction_tree<FLOAT_T, ALLOC>::random_reduction_tree(int k, long n, FLOAT_T* A)
	: k_(k), n_(n), A_(A)
{
	typename tree<FLOAT_T, ALLOC>::iterator top, root;
	top = t_.begin();
	root = t_.insert(top, nan(""));
	changed_t v;
	if (k == 2) {
		// v = fill_balanced_binary_tree(irem, root, leaves);
		v = grow_random_binary_tree(n);
	} else {
		fprintf(stderr, "generic k-ary trees not supported yet (%d)\n", k);
		throw TREE_ERROR;
	}

	if (v.inner != n-1 || v.leaf != n) {
		fprintf(stderr, "Didn't fill tree correctly: (inner=%ld leaves=%ld, n=%ld)\n",
		        v.inner, v.leaf, n_);
		throw TREE_ERROR;
	}
}

template <class FLOAT_T, class ALLOC>
FLOAT_T random_reduction_tree<FLOAT_T, ALLOC>::sum_tree()
{
	eval_tree_sum(t_.begin());
	return *t_.begin();
}

template <class FLOAT_T, class ALLOC>
FLOAT_T random_reduction_tree<FLOAT_T, ALLOC>::multiply_tree()
{
	eval_tree_product(t_.begin());
	return *t_.begin();
}

/* Make a balanced binary tree. Not random */
template <class FLOAT_T, class ALLOC>
changed_t random_reduction_tree<FLOAT_T, ALLOC>::fill_balanced_binary_tree(
		typename tree<FLOAT_T, ALLOC>::iterator c, long *L, long s, long idx)
{
	fprintf(stderr, "fill_balanced_binary_tree unimplemented\n");
	return (changed_t) {.inner = 0, .leaf = 0};
}

/* c is the current node
 * L is the tree as an array
 * s = 2k - 1 in Knuth's notation
 * idx is the index into the random double array
 * Returns: the number of leaf nodes filled
 */
template <class FLOAT_T, class ALLOC>
long random_reduction_tree<FLOAT_T, ALLOC>::fill_binary_tree(
		typename tree<FLOAT_T, ALLOC>::iterator c, long *L, long s, long idx)
{
	typename tree<FLOAT_T>::iterator l, r;
	long la; // leaves added from a subtree
	if (s % 2 == 0) { // even means leaf node
		*c = A_[idx];
		return 1;
	} else if ((s + 1) / 2 < n_) { // odd means internal node
		l = t_.append_child(c, nan(""));
		r = t_.append_child(c, nan(""));
		la = fill_binary_tree(l, L, L[s], idx);
		return la + fill_binary_tree(r, L, L[s+1], idx+la);
	} else {
		// If k == N (in Knuth's notation) then we're finished
		return 0;
	}
}

/* Add up the elements of a tree, first by filling in the internal nodes */
/* Example post-order traversal for n = 4:
 * -6.3452 ; -13.9186 ; 15.3983 ; nan ; 22.1456 ; nan ; nan */
template <class FLOAT_T, class ALLOC>
void random_reduction_tree<FLOAT_T, ALLOC>::eval_tree_sum(typename tree<FLOAT_T, ALLOC>::iterator c)
{
	typename tree<FLOAT_T, ALLOC>::sibling_iterator s;
	FLOAT_T acc = 0.;
	if (isnan(*c)) { // If not NaN then eval is done
		s = t_.begin(c);
		while (s != t_.end(c)) {
			eval_tree_sum(s);
			acc += *s;
			s++;
		}
		// Then compute the reduction
		if (isnan(acc)) {
			fprintf(stderr, "NaN encountered in eval_tree_sum\n");
			throw TREE_ERROR;
		} else {
			*c = acc;
		}
	}
}
/* // Here is how you do just a left-associative eval, not what we want here
	tree<FLOAT_T>::post_order_iterator i = t_.begin_post();
	FLOAT_T acc = 0.;
	while (i != t_.end_post()) {
		if (!isnan(*i)) {
			acc += *i;
		}
		++i;
	}
*/

template <class FLOAT_T, class ALLOC>
void random_reduction_tree<FLOAT_T, ALLOC>::eval_tree_product(typename tree<FLOAT_T, ALLOC>::iterator c)
{
	typename tree<FLOAT_T, ALLOC>::sibling_iterator s;
	FLOAT_T acc = 1.;
	if (isnan(*c)) { // If not NaN then eval is done
		s = t_.begin(c);
		while (s != t_.end(c)) {
			eval_tree_sum(s);
			acc *= *s;
			s++;
		}
		// Then compute the reduction
		if (isnan(acc)) {
			fprintf(stderr, "NaN encountered in eval_tree_product\n");
			throw TREE_ERROR;
		} else {
			*c = acc;
		}
	}
}

/* Make a random binary tree. Algorithm R from The Art of Computer
 * Programming, Volume 4, pre-fascicle 4A: A Draft of Section 7.2.1.6:
 * Generating All Trees, Donald Knuth.
 * leaves: Number of leaves in tree.
 * returns: The number of inner nodes and leaf nodes added in the subtree
 */
template <class FLOAT_T, class ALLOC>
changed_t random_reduction_tree<FLOAT_T, ALLOC>::grow_random_binary_tree(long leaves)
{
	long N = leaves - 1;
	if ((2 * N + 1) >= RAND_MAX) {
		fprintf(stderr, "tree too big\n");
		throw TREE_ERROR;
	}
	/* Allocate an array */
	long x, k, b, n, rem;
	long *L;
	L = (long *) malloc((2*N + 1)*sizeof(long));
	/* Initialize (R1) */
	n = 0;
	L[0] = 0;
	while (n < N) { /* Done? (R2) */
		/* Advance i (R3) */
		x = rand() % (4 * n + 2);
		n++;
		b = x % 2;
		k = x / 2;
		L[2*n - b] = 2*n;
		L[2*n - 1 + b] = L[k];
		L[k] = 2*n - 1;
	}
	/* Debug */
	// printf("n = %ld: [%ld", leaves, L[0]);
	// for (rem = 1; rem <= 2 * N; rem++) {
	// 	printf(", %ld", L[rem]);
	// }
	// printf("]\n");
	/* End Debug */

	/* Now, to convert to C++ tree. Leaf nodes have even numbers, internal
	 * nodes have odd numbers. */
	/* Root already initialized in constructor */
	typename tree<FLOAT_T, ALLOC>::iterator c = t_.begin();
	rem = fill_binary_tree(c, L, L[0], 0);
	free(L);
	return (changed_t) {.inner = N, .leaf = rem};
}

/* Explicit template instantiation. */
template class random_reduction_tree<double>;
template class random_reduction_tree<float>;
template class random_reduction_tree<boost::multiprecision::mpfr_float_50>;
template class random_reduction_tree<boost::multiprecision::mpfr_float_100>;
template class random_reduction_tree<boost::multiprecision::mpfr_float_500>;
template class random_reduction_tree<boost::multiprecision::mpfr_float_1000>;
template class random_reduction_tree<boost::multiprecision::mpfr_float>;
/* For completeness, here's what an explicit template instantiation for
 * class member functions looks like, though we don't need that here */
/* template random_reduction_tree<double>::random_reduction_tree(int k, long n, double* A); */

#endif

