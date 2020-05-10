#ifndef MPI_OP
#define MPI_OP
#include <mpi.h>
void noncommutative_sum(double *in, double *inout, int *len, MPI_Datatype *dptr);
#endif
