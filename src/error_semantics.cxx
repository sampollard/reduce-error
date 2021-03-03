#ifndef ERROR_SEMANTICS_CXX
#define ERROR_SEMANTICS_CXX

#include "error_semantics.hxx"

using namespace boost::multiprecision;

template <typename FLOAT_T>
mpfr_float_1000 gamma(long long int n)
{
	return n * mach_eps<FLOAT_T> / (1.0 - n * mach_eps<FLOAT_T>);
}

mpfr_float_1000 dot_e(double mag, long long int n, mpfr_float_1000 e)
{
	mpfr_float_1000 rv;
	/*  e * |x| . |y| * \gamma_n + nd(1 + \theta_{n-1}) */
	rv = e + mag * mag * n * gamma<double>(n)
	       + n * mach_del_dbl * (1.0 + gamma<double>(n-1));
	return(rv);
}

#endif
