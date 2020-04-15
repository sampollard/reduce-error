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
#define VECLEN 100

int main (int argc, char* argv[])
{
	int taskid, numtasks;
	long i, j, chunk, len=VECLEN, rc=0;
	double *a, *b;
	double mysum, allsum;

	/* MPI Initialization */
	MPI_Init (&argc, &argv);
	MPI_Comm_size (MPI_COMM_WORLD, &numtasks);
	MPI_Comm_rank (MPI_COMM_WORLD, &taskid);

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
	if (taskid == 0)
		printf("Starting omp_dotprod_mpi. Using %d tasks...\n",numtasks);

	/* Assign storage for dot product vectors
	 * We do extra here for simplicity and so rank 0 has enough room */
	a = (double*) malloc (len*sizeof(double));
	b = (double*) malloc (len*sizeof(double));
	/* TODO: The seeds get called different numbers of times for different
     * ranks */

	/* Initialize dot product vectors */
	chunk = len/numtasks;
	set_seed(42, taskid);
	for (i = chunk*taskid; i < chunk*taskid + chunk; i++) {
		a[i] = unif_rand_R();
		b[i] = unif_rand_R();
	}

	/* Perform the dot product */
	mysum = 0.0;
	for (i = chunk*taskid; i < chunk*taskid + chunk; i++) {
		mysum += a[i] * b[i];
	}

	/* After the dot product, perform a summation of results on each node */
	MPI_Reduce (&mysum, &allsum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
	if (taskid == 0)
		printf ("MPI version: dot(x,y)      = %f (%a)\n", allsum, allsum);

	/* Now, task 0 does all the work to check */
	if (taskid == 0) {
		mysum = 0.0;
		for (i=0; i<numtasks; i++) {
			set_seed(42, i);
			for (j = chunk*i; j < chunk * i + chunk; j++) {
				a[j] = unif_rand_R();
				b[j] = unif_rand_R();
				mysum += a[j] * b[j];
			}
		}
		printf ("Serial version: dot(x,y)   = %f (%a)\n", allsum, allsum);
	}

	free (a);
	free (b);

done:
	MPI_Finalize();
	return rc;
}
