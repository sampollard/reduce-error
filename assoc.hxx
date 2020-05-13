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

#ifndef FLOAT_T
#define FLOAT_T double
#endif

/* For recursive fill_binary_tree function */
typedef struct chg {
	long inner;
	long leaf;
} changed_t;

/* Look at C++ Concepts */
class random_kary_tree {
	public:
		random_kary_tree();       // Empty constructor
		random_kary_tree(int k, long n, FLOAT_T* A);  // Construct and randomize
		~random_kary_tree();      // Destructor
		FLOAT_T sum_tree();       // Add all leaves. Sum is at the root.
		FLOAT_T multiply_tree();  // Multiply all leaves. Product is at the root.
		changed_t fill_binary_tree(
			long irem, tree<FLOAT_T>::iterator parent, long lrem, FLOAT_T* A);
	private:
		tree<FLOAT_T> t;     // The tree
		int k_;              // Fan-out of tree
		long n_;             // Size of array of elements to insert
		FLOAT_T* A_;         // Elements to put in the leaves
		long irem;           // Inner nodes remaining
		long lrem;           // Leaf nodes remaining
};

#endif
