/* Create a binary tree for creating random associativities.  The idea here is
 * if you have a binary tree with n leaves, there are C_n different binary
 * trees. We randomly sample from these binary trees according to the following
 * process.
 *
 * 1.
 */

#include "tree.hxx"
#include <stdlib.h>
#include <cmath>

template <typename T>
class random_kary_tree {
	public:
		tree<T> t;           // The tree
		int k_;              // Fan-out of tree
		long n_;             // Size of array of elements to insert
		T* A_;               // Elements to put in the leaves
		long irem;           // Inner nodes remaining
		long leaf;           // Leaf nodes remaining
		random_kary_tree();  // Empty constructor
		random_kary_tree(int k, long n, T* A);  // Construct and randomize
		~random_kary_tree(); // Destructor
		T sum_tree();        // Add all leaves. Sum is at the root.
		T multiply_tree();   // Multiply all leaves. Product is at the root.
};
#include "assoc.txx"
