/*****************************************************************************
* FILE: dotprod_mpi.cxx
* DESCRIPTION:
* This file started out as omp_dotprod_mpi.c, one of a sequence of examples
* on doing a dot product in OpenMP and MPI by Blaise Barney. It has since
* morphed to be more generic MPI operations
* SOURCE: Blaise Barney
* LAST REVISED: 3/01/21	- Samuel Pollard
******************************************************************************/
/* associative_accumulate_rand generates a random tree, then sums the elements in that order
 * For example,
 *        (a+b)+c
 *         /  \
 *     (a+b)   \
 *      / \     \
 *     /   \     \
 *    a     b     c
 */
#define USAGE (\
	"mpirun -np <N> ./dotprod_mpi <len> <distr> <topology> <algorithm>\n"\
	"<len> is size of the vector being reduced. mod(N,len) must be 0\n"\
	"<distr> is the distribution to use. Choices are:\n"\
	"\trunif[0,1] runif[-1,1] runif[-1000,1000] rsubn\n"\
	"<topology> is a string for logging, best used with SimGrid\n"\
	"<algorithm> is a string for logging, best used with SimGrid\n")

#include <cstdio>
#include <string>
#include <mpi.h>
#include <stdlib.h>
#include <stdbool.h>
#include <boost/multiprecision/mpfr.hpp>
#include <boost/multiprecision/number.hpp>

#include "assoc.hxx"
#include "error_semantics.hxx"
#include "mpi_op.hxx"
#include "rand.hxx"
#include "util.hxx"

#define FLOAT_T double
using namespace boost::multiprecision;
using namespace boost::math;

/* Note: it would be more robust to use ACCUMULATOR().operator()(a,b) instead
 * of a ACC_OP b, but this doesn't work for mpfr values */
/* #define ACCUMULATOR std::multiplies<FLOAT_T> */
/* #define ACC_OP * */
#define ACCUMULATOR std::plus<FLOAT_T>
#define ACC_OP +

const bool is_sum  = std::is_same<std::plus<FLOAT_T>, ACCUMULATOR>::value;
const bool is_prod = std::is_same<std::multiplies<FLOAT_T>, ACCUMULATOR>::value;
/* Fill in random vectors and do dot product according to MPI canonical ordering */
FLOAT_T can_mpi_dot(int numtasks, long long len, FLOAT_T* as, FLOAT_T* bs, FLOAT_T (*rand_a)(), FLOAT_T (*rand_b)(), FLOAT_T *rank_sum);
/* Left-associative dot product */
FLOAT_T dot(long long len, FLOAT_T* a, FLOAT_T* b);
/* Left-associative dot product with MPFR accumulator */
mpfr_float_1000 mpfr_dot(FLOAT_T *a, FLOAT_T *b, long long len);

int main (int argc, char* argv[])
{
	int taskid, numtasks;
	long i, chunk, rc=0;
	long long len, height;
	MPI_Op nc_sum_op;
	std::string distr, topo, algo;
	FLOAT_T *a, *b, *as, *bs, *rank_sum;
	FLOAT_T localsum, nc_sum, par_sum, can_mpi_sum, rand_sum, serial_sum;
	FLOAT_T starttime, endtime, ptime, ctime, stime, mpfrtime, randtreetime;
	FLOAT_T (*rand_flt_a)(); // Function to generate a random float
	FLOAT_T (*rand_flt_b)(); // Function to generate a random float
	mpfr_float_1000 mpfr_acc;
	mpfr_float_1000 error, result;
	FLOAT_T magnitude = 0.0;
	union udouble {
		double d;
		unsigned long u;
	} pv;

	/* MPI Initialization */
	MPI_Init(&argc, &argv);
	MPI_Comm_size(MPI_COMM_WORLD, &numtasks);
	MPI_Comm_rank(MPI_COMM_WORLD, &taskid);

	/* Parse arguments */
	if (argc != 5) {
		if (taskid == 0) {
			fprintf(stderr, "Expected 4 arguments, found %d\n", argc-1);
			fprintf(stderr, USAGE);
		}
		rc = 1;
		goto done;
	}
	len = atoll(argv[1]);
	if (len <= 0 || len % numtasks != 0) {
		if (taskid == 0) {
			fprintf(stderr,
					"Number of MPI ranks (%d) must divide vector size (%lld)\n%s",
					numtasks, len, USAGE);
		}
		rc = 1;
		goto done;
	}
	/* Select distribution for random floating point numbers */
	distr = argv[2];
	rc = parse_distr<FLOAT_T>(distr, &magnitude, &rand_flt_a)
		|| parse_distr<FLOAT_T>(distr, &magnitude, &rand_flt_b);
	if (rc != 0) {
		if (taskid == 0) {
			fprintf(stderr, "Unrecognized distribution:\n%s", USAGE);
		}
		goto done;
	}
	topo = argv[3];
	algo = argv[4];

	/* Create custom MPI Reduce that is just + but not commutative */
	rc = MPI_Op_create((MPI_User_function *) noncommutative_sum, false, &nc_sum_op);
	if (rc != 0) {
		if (taskid == 0) {
			fprintf(stderr, "Could not create MPI op noncommutative sum\n");
		}
		rc = 1;
		goto done;
	}

	/* Assign storage for dot product vectors
	 * We do extra here for simplicity and so rank 0 has enough room */
	// XXX: Do not need to malloc as and bs on each MPI process, just on rank 0
	// This is a bit trickier to make sure the rand is consistent though.
	a  = (FLOAT_T*) malloc(len*sizeof(FLOAT_T));
	b  = (FLOAT_T*) malloc(len*sizeof(FLOAT_T));
	as = (FLOAT_T*) malloc(len*sizeof(FLOAT_T));
	bs = (FLOAT_T*) malloc(len*sizeof(FLOAT_T));
	rank_sum = (FLOAT_T*) malloc (numtasks*sizeof(FLOAT_T));

	/* Initialize dot product vectors */
	chunk = len/numtasks;
	set_seed(ASSOC_SEED, 0);
	srand(ASSOC_SEED);
	for (i = 0; i < len; i++) {
		a[i] = rand_flt_a();
		b[i] = rand_flt_b();
	}

	/* Perform the dot product in parallel */
	starttime = MPI_Wtime();
	localsum = 0.0;
	for (i = chunk*taskid; i < chunk*taskid + chunk; i++) {
		localsum += a[i] * b[i];
	}

	/* After the dot product, perform a summation of results on each node */
	MPI_Reduce(&localsum, &par_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
	endtime = MPI_Wtime();
	MPI_Reduce(&localsum, &nc_sum, 1, MPI_DOUBLE, nc_sum_op, 0, MPI_COMM_WORLD);
	ptime = endtime - starttime;

	/* Now, task 0 does all the work to check. The canonical ordering * is increasing taskid */
	set_seed(ASSOC_SEED, 0);
	srand(ASSOC_SEED);
	if (taskid == 0) {
		// Do the canonical MPI dot product summation
		starttime = MPI_Wtime();
		can_mpi_sum = can_mpi_dot(numtasks, len, as, bs, rand_flt_a, rand_flt_b, rank_sum);
		endtime = MPI_Wtime();
		ctime = endtime - starttime;

		// Do the serial sum
		starttime = MPI_Wtime();
		serial_sum = dot(len, a, b);
		endtime = MPI_Wtime();
		stime = endtime - starttime;

		// Generate a random dot product on the MPI ranks
		starttime = MPI_Wtime();
		rand_sum = associative_accumulate_rand<FLOAT_T>(numtasks, rank_sum, is_sum, &height);
		endtime = MPI_Wtime();
		randtreetime = endtime - starttime;

		// MPFR dot product
		starttime = MPI_Wtime();
		mpfr_acc = mpfr_dot(as, bs, len);
		endtime = MPI_Wtime();
		mpfrtime = endtime - starttime;

		// Error analysis
		error = dot_e(magnitude, len, 0.0);

		// TODO: Figure out the height of MPI Reduce and MPI noncommutative sum, and canonical MPI sum
		// TODO: Add in timings for MPFR and serial summations.

		// Print header then different dot products
		printf("numtasks\tveclen\ttopology\tdistribution\treduction algorithm\torder\theight\ttime\tFP (decimal)\tFP (%%a)\tFP (hex)\n");
		pv.d = serial_sum;
		printf("%d\t%lld\t%s\t%s\t%s\tLeft assoc\t%lld\t%f\t%.15f\t%a\t0x%lx\n",
			numtasks, len, topo.c_str(), distr.c_str(), algo.c_str(), len-1, stime, serial_sum, serial_sum, pv.u);
		pv.d = rand_sum;
		printf("%d\t%lld\t%s\t%s\t%s\tRandom assoc\t%lld\t%f\t%.15f\t%a\t0x%lx\n",
			numtasks, len, topo.c_str(), distr.c_str(), algo.c_str(), height, randtreetime, rand_sum, rand_sum, pv.u);
		pv.d = par_sum;
		printf("%d\t%lld\t%s\t%s\t%s\tMPI Reduce\t%lld\t%f\t%.15f\t%a\t0x%lx\n",
			numtasks, len, topo.c_str(), distr.c_str(), algo.c_str(), (long long) ceil(log2(numtasks)), ptime, par_sum, par_sum, pv.u);
		pv.d = nc_sum;
		printf("%d\t%lld\t%s\t%s\t%s\tMPI noncomm sum\t%lld\t%f\t%.15f\t%a\t0x%lx\n",
			numtasks, len, topo.c_str(), distr.c_str(), algo.c_str(), (long long) numtasks-1, ptime, nc_sum, nc_sum, pv.u);
		pv.d = can_mpi_sum;
		printf("%d\t%lld\t%s\t%s\t%s\tCanonical MPI\t%lld\t%f\t%.15f\t%a\t0x%lx\n",
			numtasks, len, topo.c_str(), distr.c_str(), algo.c_str(), (long long) numtasks-1, ctime, can_mpi_sum, can_mpi_sum, pv.u);
		mpfr_printf("%d\t%lld\t%s\t%s\t%s\tMPFR(%d) left assoc\t%lld\t%f\t%.20RNf\t%.20RNa\t%RNa\n",
			numtasks, len, topo.c_str(), distr.c_str(), algo.c_str(),
			std::numeric_limits<mpfr_float_1000>::digits, // Precision of MPFR
			len - 1, mpfrtime, mpfr_acc, mpfr_acc, mpfr_acc);
		mpfr_printf("%d\t%lld\t%s\t%s\t%s\tPredicted error\t%lld\t%f\t%.20RNf\t%.20RNa\t%RNa\n",
			numtasks, len, topo.c_str(), distr.c_str(), algo.c_str(),
			len-1, nan(""), error, error, error);
		result = serial_sum - mpfr_acc;
		mpfr_printf("%d\t%lld\t%s\t%s\t%s\tLeft assoc error\t%lld\t%f\t%.20RNf\t%.20RNa\t%RNa\n",
			numtasks, len, topo.c_str(), distr.c_str(), algo.c_str(),
			len - 1, nan(""), result, result, result);
	}

	free(a);
	free(b);
	free(as);
	free(bs);
	free(rank_sum);
	MPI_Op_free(&nc_sum_op);

done:
	MPI_Finalize();
	return rc;
}

FLOAT_T can_mpi_dot(int numtasks, long long len, FLOAT_T* as, FLOAT_T* bs, FLOAT_T (*rand_a)(), FLOAT_T (*rand_b)(), FLOAT_T *rank_sum)
{
	int i, j;
	int chunk = len/numtasks;
	FLOAT_T can_mpi_sum = 0.0;
	FLOAT_T localsum = 0.0;
	for (i = 0; i < numtasks; i++) {
		rank_sum[i] = 0.0;
		for (j = chunk*i; j < chunk * i + chunk; j++) {
			as[j] = rand_a();
			bs[j] = rand_b();
			/* // Debug
			if (as[j] != a[j] || bs[j] != b[j]) {
					fprintf(stderr, "Results differ: (%a != %a, %a != %a)\n",
							as[j], a[j], bs[j], b[j]);
			}
			*/
			rank_sum[i] += as[j] * bs[j];
			localsum += as[j] * bs[j];
		}
	}
	for (i = 0; i < numtasks; i++) {
		can_mpi_sum += rank_sum[i];
	}
	return(can_mpi_sum);
}

FLOAT_T dot(long long len, FLOAT_T* a, FLOAT_T* b)
{
	FLOAT_T acc = 0.0;
	for (long long i = 0; i < len; i++) {
		acc = acc + a[i] * b[i];
	}
	return acc;
}

mpfr_float_1000 mpfr_dot(FLOAT_T *a, FLOAT_T *b, long long len)
{
	mpfr_float_1000 acc;
	acc = 0.0;
	for (long long i = 0; i < len; i++) {
		acc = acc + a[i] * b[i];
	}
	return(acc);
}
