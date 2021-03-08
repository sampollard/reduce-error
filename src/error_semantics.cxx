#ifndef ERROR_SEMANTICS_CXX
#define ERROR_SEMANTICS_CXX

#include <vector>

#include "error_semantics.hxx"

using namespace boost::multiprecision;

template <typename FLOAT_T>
MPFR_T_DEFAULT gamma(long long int n)
{
	return n * mach_eps<FLOAT_T> / (1.0 - n * mach_eps<FLOAT_T>);
}

MPFR_T_DEFAULT dot_e(double mag, long long int n, MPFR_T_DEFAULT e)
{
	MPFR_T_DEFAULT rv;
	/*  e * |x| . |y| * \gamma_n + nd(1 + \theta_{n-1}) */
	rv = e + mag * mag * n * gamma<double>(n)
	       + n * mach_del_dbl * (1.0 + gamma<double>(n-1));
	return(rv);
}

template <class FLOAT_T, class MPFR_T>
Vec_E<FLOAT_T, MPFR_T>::Vec_E() { };

template <class FLOAT_T, class MPFR_T>
Vec_E<FLOAT_T, MPFR_T>::~Vec_E() { };

template <class FLOAT_T, class MPFR_T>
Vec_E(long long n, FLOAT_T ub, FLOAT_T lb, FLOAT_T* x)
	: ub_(ub), lb_(lb)
{
	data_.reserve(n);
	for (long long i = 0; i < n; i++) {
		data_[i] = x[i];
	}
}


template <class FLOAT_T, class MPFR_T>
long long Vec_E::length() { return data_.size(); }

template <class FLOAT_T, class MPFR_T>
MPFR_T error_ub() { return error_ub_; }

template <class FLOAT_T, class MPFR_T>
MPFR_T error_lb() { return error_lb_; }

/* Explicit template instantiation. */
template class Vec_E<double, mpfr_float_1000>;
template class Vec_E<float, mpfr_float_1000>;
#endif
