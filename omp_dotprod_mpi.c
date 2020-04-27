/*****************************************************************************
* FILE: omp_dotprod_mpi.c
* DESCRIPTION:
*   This simple program is the MPI version of a dot product and the third
*   of four codes used to show the progression from a serial program to a
*   hybrid MPI/OpenMP program.  The relevant codes are:
*      - omp_dotprod_serial.c  - Serial version
*      - omp_dotprod_openmp.c  - OpenMP only version
*      - omp_dotprod_mpi.c     - MPI only version
*      - omp_dotprod_hybrid.c  - Hybrid MPI and OpenMP version
* SOURCE: Blaise Barney
* LAST REVISED: 4/14/20 - Samuel Pollard
******************************************************************************/

#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

#include "rand.h"

/* Define length of dot product vectors */
#define VECLEN 7200 /* 720 = 2*3*4*5*6 */
// #define RAND_01a() subnormal_rand()
#define RAND_01a() unif_rand_R();
#define RAND_01b() (1.0);

int main (int argc, char* argv[])
{
	int taskid, numtasks;
	long i, j, chunk, len=VECLEN, rc=0;
	double *a, *b, *as, *bs, *ser_sum;
	double mysum, par_sum;
	union udouble {
	  double d;
	  unsigned long u;
	} pv;


	/* MPI Initialization */
	MPI_Init(&argc, &argv);
	MPI_Comm_size(MPI_COMM_WORLD, &numtasks);
	MPI_Comm_rank(MPI_COMM_WORLD, &taskid);

	if (len % numtasks != 0) {
		if (taskid == 0) {
			fprintf(stderr,
					"Number of MPI ranks (%d) must divide vector size (%ld)\n",
					numtasks, len);
		}
		rc = 1;
		goto done;
	}

	/* Each MPI task performs the dot product, obtains its partial sum, and
	 * then calls MPI_Reduce to obtain the global sum.  */
	if (taskid == 0) {
		printf("Starting omp_dotprod_mpi. Using %d processes...\n",numtasks);
    }

	/* Assign storage for dot product vectors
	 * We do extra here for simplicity and so rank 0 has enough room */
	a  = (double*) malloc(len*sizeof(double));
	b  = (double*) malloc(len*sizeof(double));
	as = (double*) malloc(len*sizeof(double));
	bs = (double*) malloc(len*sizeof(double));
	ser_sum = (double *) malloc (numtasks*sizeof(double));

	/* Initialize dot product vectors */
	chunk = len/numtasks;
	set_seed(42, 0);
	for (i = 0; i < len; i++) {
		a[i] = RAND_01a();
		b[i] = RAND_01b();
	}

	/* Perform the dot product */
	mysum = 0.0;
	for (i = chunk*taskid; i < chunk*taskid + chunk; i++) {
		mysum += a[i] * b[i];
	}

	/* After the dot product, perform a summation of results on each node */
	MPI_Reduce(&mysum, &par_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
	if (taskid == 0) {
		pv.d = par_sum;
		printf("MPI version: dot(x,y)     =\t%a\t0x%lx\n", par_sum, pv.u);
	}

	/* Now, task 0 does all the work to check. The canonical ordering
	 * is increasing taskid */
	set_seed(42, 0);
	if (taskid == 0) {
		for (i = 0; i < numtasks; i++) {
			ser_sum[i] = 0.0;
			for (j = chunk*i; j < chunk * i + chunk; j++) {
				as[j] = RAND_01a();
				bs[j] = RAND_01b();
				/* // Debug
				if (as[j] != a[j] || bs[j] != b[j]) {
						fprintf(stderr, "Results differ: (%a != %a, %a != %a)\n",
						        as[j], a[j], bs[j], b[j]);
				}
				*/
				ser_sum[i] += as[j] * bs[j];
			}
		}
		mysum = 0.0;
		for (i = 0; i < numtasks; i++) {
			mysum += ser_sum[i];
		}
		pv.d = mysum;
		printf("Serial version: dot(x,y)  =\t%a\t0x%lx\n", mysum, pv.u);
	}

	free(a);
	free(b);
	free(as);
	free(bs);

done:
	MPI_Finalize();
	return rc;
}
