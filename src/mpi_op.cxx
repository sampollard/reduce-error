/* MPI Operations */
#include "mpi_op.hxx"

void noncommutative_sum(double *in, double *inout, int *len, MPI_Datatype *dptr)
{
	long int i;
	double s;
	for (i = 0; i < *len; ++i) {
		s = (*inout) + (*in);
		*inout = s;
		in++;
		inout++;
	}
}
