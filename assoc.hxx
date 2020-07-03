/* Create a binary tree for creating random associativities.  The idea here is
 * if you have a binary tree with n leaves, there are C_n different binary
 * trees. We randomly sample from these binary trees.
 */

#ifndef ASSOC_HXX
#define ASSOC_HXX
#include "tree.hxx"
#include <stdlib.h>
#include <cmath>

#ifndef FLOAT_T
#define FLOAT_T double
#endif

#define TREE_ERROR 3

/* For recursive fill_binary_tree function */
typedef struct chg {
	long inner;
	long leaf;
} changed_t;

class random_reduction_tree {
	public:
		random_reduction_tree();   // Empty constructor
		random_reduction_tree(int k, long n, FLOAT_T* A);  // Construct and randomize
		~random_reduction_tree(); // Destructor
		FLOAT_T sum_tree();       // Add all leaves. Sum is at the root.
		FLOAT_T multiply_tree();  // Multiply all leaves. Product is at the root.
	private:
		changed_t grow_random_binary_tree(long leaves);
		long fill_binary_tree(tree<FLOAT_T>::iterator c, long *L, long s, long idx);
		changed_t fill_balanced_binary_tree(
				tree<FLOAT_T>::iterator c, long *L, long s, long idx);
		void eval_tree_sum(tree<FLOAT_T>::iterator c);
		void eval_tree_product(tree<FLOAT_T>::iterator c);
		tree<FLOAT_T> t_;         // The tree
		int k_;                   // Fan-out of tree
		long n_;                  // Size of array of elements to insert
		FLOAT_T* A_;              // Elements to put in the leaves
		long irem;                // Inner nodes remaining
		long lrem;                // Leaf nodes remaining
};
#endif
