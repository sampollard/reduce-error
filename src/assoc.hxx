/* Create a binary tree for creating random associativities.  The idea here is
 * if you have a binary tree with n leaves, there are C_n different binary
 * trees. We randomly sample from these binary trees.
 *
 * While template classes are usually only in header files, we add
 * in a compiled file (assoc.cxx) so we have explicit instantiation
 * for each argument; this is because the random_reduction_tree
 * only makes sense for types which have the * and + operators.
 */

#ifndef ASSOC_HXX
#define ASSOC_HXX

#include "tree.hxx"

#include <stdlib.h>
#include <cmath>

#define TREE_ERROR 3

/* For recursive fill_binary_tree function */
typedef struct chg {
	long inner;
	long leaf;
} changed_t;

template <class FLOAT_T, class ALLOC = std::allocator<tree_node_<FLOAT_T> > >
class random_reduction_tree {
	public:
		random_reduction_tree();   // Empty constructor
		random_reduction_tree(int k, long n, FLOAT_T* A);  // Construct and randomize
		~random_reduction_tree(); // Destructor
		int height();             // Height of the tree
		FLOAT_T sum_tree();       // Add all leaves. Sum is at the root.
		FLOAT_T multiply_tree();  // Multiply all leaves. Product is at the root.
	private:
		changed_t grow_random_binary_tree(long leaves);
		long fill_binary_tree(typename tree<FLOAT_T, ALLOC>::iterator c, long *L, long s, long idx);
		changed_t fill_balanced_binary_tree(
				typename tree<FLOAT_T, ALLOC>::iterator c, long *L, long s, long idx);
		void eval_tree_sum(typename tree<FLOAT_T, ALLOC>::iterator c);
		void eval_tree_product(typename tree<FLOAT_T, ALLOC>::iterator c);
		tree<FLOAT_T, ALLOC> t_;  // The tree
		int k_;                   // Fan-out of tree
		long n_;                  // Size of array of elements to insert
		FLOAT_T* A_;              // Elements to put in the leaves
		long irem;                // Inner nodes remaining
		long lrem;                // Leaf nodes remaining
};

#endif

