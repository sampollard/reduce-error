/**********************************************************************
 * FILE: mpi_pi_reduce.c
 * DESCRIPTION:
 *   MPI pi Calculation Example - C Version
 *   Collective Communication example:
 *   This program calculates pi using a "dartboard" algorithm.  See
 *   Fox et al.(1988) Solving Problems on Concurrent Processors, vol.1
 *   page 207.  All processes contribute to the calculation, with the
 *   master averaging the values for pi. This version uses mpc_reduce to
 *   collect results
 * AUTHOR: Blaise Barney. Adapted from Ros Leibensperger, Cornell Theory
 *   Center. Converted to MPI: George L. Gusciora, MHPCC (1/95)
 * LAST REVISED: 06/13/13 Blaise Barney
**********************************************************************/
#include <mpi.h>
#include <cstdio>
#include <stdlib.h>
#include <unistd.h>

#include "rand.hxx"

double dboard (int darts);
#define DARTS 5000     /* number of throws at dartboard */
#define ROUNDS 10      /* number of times "darts" is iterated */
#define MASTER 0       /* task ID of master task */

int main (int argc, char *argv[])
{
	double homepi,      /* value of pi calculated by current task */
		pisum,          /* sum of tasks' pi values */
		pi,             /* average of pi after "darts" is thrown */
		avepi;          /* average pi value for all iterations */
	int taskid,         /* task ID - also used as seed number */
		numtasks,       /* number of tasks */
		rc,             /* return code */
		i;
	double *serial_pi;           /* Array for pi values */
	double spisum, spi, savepi;  /* Serial pi and pisum */
	unsigned int *seed_vault;    /* Array for random seeds */
	int j;

	// MPI_Status status;

	/* Obtain number of tasks and task ID */
	MPI_Init(&argc,&argv);
	MPI_Comm_size(MPI_COMM_WORLD,&numtasks);
	MPI_Comm_rank(MPI_COMM_WORLD,&taskid);
	usleep((useconds_t) rand()/10000);

	if (taskid == 0)
		printf("Starting mpi_pi_reduce. Using %d tasks...\n", numtasks);

	/* Set seed for random number generator equal to task ID */
	set_seed(42, taskid);
	avepi = 0;
	for (i = 0; i < ROUNDS; i++) {
		/* All tasks calculate pi using dartboard algorithm */
		homepi = dboard(DARTS);

		/* Use MPI_Reduce to sum values of homepi across all tasks
		 * Master will store the accumulated value in pisum
		 * - homepi is the send buffer
		 * - pisum is the receive buffer (used by the receiving task only)
		 * - the size of the message is sizeof(double)
		 * - MASTER is the task that will receive the result of the reduction
		 *   operation
		 * - MPI_SUM is a pre-defined reduction function (double-precision
		 *   floating-point vector addition).  Must be declared extern.
		 * - MPI_COMM_WORLD is the group of tasks that will participate.
		 */

		rc = MPI_Reduce(&homepi, &pisum, 1, MPI_DOUBLE, MPI_SUM,
		                MASTER, MPI_COMM_WORLD);

		/* Master computes average for this iteration and all iterations */
		if (taskid == MASTER) {
			pi = pisum/numtasks;
			avepi = ((avepi * i) + pi)/(i + 1);
			// printf("   After %8d throws, average value of pi = %10.16f\n",
			//         (DARTS * (i + 1)),avepi);
		}
	}

	/* Now, do it all on Rank 0 and see if it matches */
	if (taskid == MASTER) {
		serial_pi = (double *) malloc(numtasks * sizeof(double));
		seed_vault = (unsigned int *) malloc(2 * numtasks * sizeof(unsigned int));
		/* Reinitialize seeds */
		for (j = 0; j < numtasks; j++) {
			seed_vault[2*j  ] = 42;
			seed_vault[2*j+1] = j;
			serial_pi[j] = 0.0;
		}
		for (i = 0; i < ROUNDS; i++) {
			spisum = 0.0;
			for (j = 0; j < numtasks; j++) {
				set_seed(seed_vault[2*j], seed_vault[2*j+1]);
				serial_pi[j] = dboard(DARTS); /* Changes seed */
				get_seed(&seed_vault[2*j], &seed_vault[2*j+1]);
				/* Taking the place of MPI_Reduce */
				spisum += serial_pi[j];
			}
			spi = spisum/numtasks;
			savepi = ((savepi * i) + spi)/(i + 1);
		}
		free(serial_pi);
		free(seed_vault);
	}

	if (taskid == MASTER) {
		printf ("Final value of pi        = %a\n",pi);
		printf ("Final value of serial pi = %a\n",spi);
		// printf ("Real value of PI: 3.1415926535897\n");
	}

	MPI_Finalize();
	return rc;
}



/**************************************************************************
* subroutine dboard
* DESCRIPTION:
*   Used in pi calculation example codes.
*   See mpi_pi_send.c and mpi_pi_reduce.c
*   Throw darts at board.  Done by generating random numbers
*   between 0 and 1 and converting them to values for x and y
*   coordinates and then testing to see if they "land" in
*   the circle."  If so, score is incremented.  After throwing the
*   specified number of darts, pi is calculated.  The computed value
*   of pi is returned as the value of this function, dboard.
*
*   Explanation of constants and variables used in this function:
*   darts       = number of throws at dartboard
*   score       = number of darts that hit circle
*   n           = index variable
*   r           = random number scaled between 0 and 1
*   x_coord     = x coordinate, between -1 and 1
*   x_sqr       = square of x coordinate
*   y_coord     = y coordinate, between -1 and 1
*   y_sqr       = square of y coordinate
*   pi          = computed value of pi
****************************************************************************/

double dboard(int darts)
{
	#define sqr(x)	((x)*(x))
	long random(void);
	double x_coord, y_coord, pi, r;
	int score, n;
	unsigned int cconst;  /* must be 4-bytes in size */
	/*************************************************************************
	 * The cconst variable must be 4 bytes. We check this and bail if it is
	 * not the right size
	 ************************************************************************/
	if (sizeof(cconst) != 4) {
		printf("Wrong data size for cconst variable in dboard routine!\n");
		printf("See comments in source file. Quitting.\n");
		exit(1);
		}
		/* 2 bit shifted to MAX_RAND later used to scale random number between 0 and 1 */
		cconst = 2 << (31 - 1);
		score = 0;

		/* "throw darts at board" */
		for (n = 1; n <= darts; n++) {
			/* generate random numbers for x and y coordinates */
			r = unif_rand_R();
			x_coord = (2.0 * r) - 1.0;
			r = unif_rand_R();
			y_coord = (2.0 * r) - 1.0;

			/* if dart lands in circle, increment score */
			if ((sqr(x_coord) + sqr(y_coord)) <= 1.0)
				score++;
			}

	/* calculate pi */
	pi = 4.0 * (double)score/(double)darts;
	return(pi);
}
