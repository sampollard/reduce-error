/*****************************************************************************
* FILE: dotprod_mpi.cxx
* DESCRIPTION:
*   This simple program is the MPI version of a dot product and the third
*   of four codes used to show the progression from a serial program to a
*   hybrid MPI/OpenMP program.  The (original) relevant codes are:
*      - omp_dotprod_serial.c  - Serial version
*      - omp_dotprod_openmp.c  - OpenMP only version
*      + omp_dotprod_mpi.c     - MPI only version
*      - omp_dotprod_hybrid.c  - Hybrid MPI and OpenMP version
* SOURCE: Blaise Barney
* LAST REVISED: 5/7/20 - Samuel Pollard
******************************************************************************/
#define USAGE "mpirun -np <N> ./dotprod_mpi <veclen> <topology>"

#include <cstdio>
#include <mpi.h>
#include <stdlib.h>
#include <stdbool.h>

#include "rand.hxx"
#include "assoc.hxx"
#include "mpi_op.hxx"

// Define what kind of pseudo RNG you're using.
//#define RAND_01a() (subnormal_rand())
//#define RAND_01b() (subnormal_rand())
#define RAND_01a() (unif_rand_R())
#define RAND_01b() (unif_rand_R()*2 - 1.0)

/* This function generates a random tree, then sums the elements in that order
 * For example,
 *        (a+b)+c
 *         /  \
 *     (a+b)   \
 *      / \     \
 *    /   \      \
 *   a    b      c
 */
template <typename T>
T associative_sum_rand(long n, T* A, int seed);

int main (int argc, char* argv[])
{
	int taskid, numtasks;
	long i, j, chunk, len, rc=0;
	double *a, *b, *as, *bs, *rank_sum;
	double mysum, nc_sum, par_sum, can_mpi_sum, rassoc_sum;
	double starttime, endtime, ptime;
	union udouble {
		double d;
		unsigned long u;
	} pv;


	/* MPI Initialization */
	MPI_Init(&argc, &argv);
	MPI_Comm_size(MPI_COMM_WORLD, &numtasks);
	MPI_Comm_rank(MPI_COMM_WORLD, &taskid);

	len = atol(argv[1]);
	if (len <= 0 || len % numtasks != 0 || argc != 3) {
		if (taskid == 0) {
			fprintf(stderr, USAGE "\n");
			fprintf(stderr,
					"Number of MPI ranks (%d) must divide vector size (%ld)\n",
					numtasks, len);
		}
		rc = 1;
		goto done;
	}
	/* Create custom MPI Reduce that is just + but not commutative */
	MPI_Op nc_sum_op;
	rc = MPI_Op_create((MPI_User_function *) noncommutative_sum, false, &nc_sum_op);
	if (rc != 0) {
		if (taskid == 0) {
			fprintf(stderr, "Could not create MPI op noncommutative sum\n");
		}
		goto done;
	}

	/* Assign storage for dot product vectors
	 * We do extra here for simplicity and so rank 0 has enough room */
	a  = (double*) malloc(len*sizeof(double));
	b  = (double*) malloc(len*sizeof(double));
	as = (double*) malloc(len*sizeof(double));
	bs = (double*) malloc(len*sizeof(double));
	rank_sum = (double *) malloc (numtasks*sizeof(double));

	/* Initialize dot product vectors */
	chunk = len/numtasks;
	set_seed(42, 0);
	for (i = 0; i < len; i++) {
		a[i] = RAND_01a();
		b[i] = RAND_01b();
	}

	/* Perform the dot product */
	starttime = MPI_Wtime();
	mysum = 0.0;
	for (i = chunk*taskid; i < chunk*taskid + chunk; i++) {
		mysum += a[i] * b[i];
	}

	/* After the dot product, perform a summation of results on each node */
	MPI_Reduce(&mysum, &par_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
	MPI_Reduce(&mysum, &nc_sum, 1, MPI_DOUBLE, nc_sum_op, 0, MPI_COMM_WORLD);
	endtime = MPI_Wtime();
	ptime = endtime - starttime;

	/* Now, task 0 does all the work to check. The canonical ordering
	 * is increasing taskid */
	set_seed(42, 0);
	if (taskid == 0) {
		mysum = 0.0;
		for (i = 0; i < numtasks; i++) {
			rank_sum[i] = 0.0;
			for (j = chunk*i; j < chunk * i + chunk; j++) {
				as[j] = RAND_01a();
				bs[j] = RAND_01b();
				/* // Debug
				if (as[j] != a[j] || bs[j] != b[j]) {
						fprintf(stderr, "Results differ: (%a != %a, %a != %a)\n",
						        as[j], a[j], bs[j], b[j]);
				}
				*/
				rank_sum[i] += as[j] * bs[j];
				mysum += as[j] * bs[j];
			}
		}
		can_mpi_sum = 0.0;
		for (i = 0; i < numtasks; i++) {
			can_mpi_sum += rank_sum[i];
		}
		printf("numtasks\tveclen\ttopology\talgorithm\tparallel time\tFP (decimal)\tFP (%%a)\tFP (hex)\n");

		// Generate a random summation

		// rassoc_sum = associative_sum_rand<double>(numtasks, rank_sum, 1);
		// pv.d = rassoc_sum;
		// printf("Random assocs:     dot(x,y) =\t%a\t0x%lx\n", rassoc_sum, pv.u);
		pv.d = par_sum;
		printf("% 5d\t% 10ld\t%s\tMPI Reduce       \t%f\t%.15f\t%a\t0x%lx\n", numtasks, len, argv[2], ptime, par_sum, par_sum, pv.u);
		pv.d = nc_sum;
		printf("% 5d\t% 10ld\t%s\tMPI NC sum       \t%f\t%.15f\t%a\t0x%lx\n", numtasks, len, argv[2], ptime, nc_sum, nc_sum, pv.u);
		pv.d = can_mpi_sum;
		printf("% 5d\t% 10ld\t%s\tCanonical MPI    \t%f\t%.15f\t%a\t0x%lx\n", numtasks, len, argv[2], ptime, can_mpi_sum, can_mpi_sum, pv.u);
		pv.d = mysum;
		printf("% 5d\t% 10ld\t%s\tSerial left assoc\t%f\t%.15f\t%a\t0x%lx\n", numtasks, len, argv[2], ptime, mysum, mysum, pv.u);
	}

	free(a);
	free(b);
	free(as);
	free(bs);
	free(rank_sum);

done:
	MPI_Finalize();
	return rc;
}

/* Sum the array, using random associations. That is, this will do things like
 * (a+b)+c or a+(b+c). There are C_n different ways to associate the sum of an
 * array, where C_n is the nth Catalan number. This function has the side-effect
 * of setting the seed and calling rand() many times.
 */
template <typename T>
T associative_sum_rand(long n, T* A, int seed)
{
	srand(seed);
	random_kary_tree t;
	try {
		t = random_kary_tree(2, n, A);
	} catch (int e) {
		return 0.0/0.0;
	}
	return t.sum_tree();
}
