/* Semantics of floating-point error.
 * Given an operation, return the error bounds.
 */
#ifndef ERROR_SEMANTICS_HXX
#define ERROR_SEMANTICS_HXX

#include <algorithm>
#include <complex>
#include <limits>
#include <typeinfo>
#include <vector>
#include <assert.h>
#include <boost/multiprecision/mpfr.hpp>
#include <boost/multiprecision/number.hpp>

using namespace boost::multiprecision;
using namespace boost::math;

#define MPFR_T_DEFAULT mpfr_float_1000

#define ANALYSIS_EXCEPTION 4

/* If for example we want complex instead of real, access
 * with x.real() and x.imag() */
#define COMPLEX_T (std::complex<double>)

template <typename FLOAT_T>
const MPFR_T_DEFAULT mach_eps = std::numeric_limits<FLOAT_T>::epsilon();

const MPFR_T_DEFAULT mach_eps_flt = mach_eps<float>;
const MPFR_T_DEFAULT mach_eps_dbl = mach_eps<double>;
/* TODO:
 * - machine epsilon for complex
 * - machine delta for round-to-zero
 * - machine epsilon for complex
 * - machine delta for complex
 */
/* TODO: Figure out how to */
const MPFR_T_DEFAULT mach_del_flt =
	pow(2, std::numeric_limits<float>::min_exponent - 1)*mach_eps<float>;
const MPFR_T_DEFAULT mach_del_dbl =
	pow(2, std::numeric_limits<double>::min_exponent - 1)*mach_eps<double>;

template <class FLOAT_T, class MPFR_T = MPFR_T_DEFAULT >
class Scal_E {
	public:
		// Empty constructor
		Scal_E();
		// Fill scalar with upper/lower bounds
		Scal_E(FLOAT_T x, FLOAT_T lb, FLOAT_T ub);
		// Don't fill scalar, just do symbolic computations
		Scal_E(FLOAT_T lb, FLOAT_T ub, MPFR_T error);
		// Destructor
		~Scal_E();
		long long length();
		FLOAT_T lb();
		FLOAT_T ub();
		MPFR_T error_lb();
		MPFR_T error_ub();
	private:
		FLOAT_T data_;
		FLOAT_T lb_;
		FLOAT_T ub_;
		MPFR_T error_lb_;
		MPFR_T error_ub_;
		MPFR_T inf_norm_;
};

template <class FLOAT_T, class MPFR_T = MPFR_T_DEFAULT >
class Vec_E {
	public:
		// Empty constructor
		Vec_E();
		// Fill vector
		// Vec_E(long long n, FLOAT_T* x);
		// Fill vector with upper/lower bounds
		Vec_E(FLOAT_T *x, long long n, FLOAT_T lb, FLOAT_T ub);
		// Don't fill vector, just do symbolic computations
		Vec_E(long long n, FLOAT_T lb, FLOAT_T ub);
		// Destructor
		~Vec_E();
		long long length();
		FLOAT_T lb();
		FLOAT_T ub();
		MPFR_T error_lb();
		MPFR_T error_ub();
	private:
		std::vector<FLOAT_T> data_;
		long long n_;
		FLOAT_T lb_;
		FLOAT_T ub_;
		MPFR_T error_lb_;
		MPFR_T error_ub_;
		MPFR_T inf_norm_;
};

/* Operations on vectors */
/* Given two vectors, return a scalar with error bounds */
template <typename FLOAT_T>
Scal_E<FLOAT_T> dot_e(Vec_E<FLOAT_T> x, Vec_E<FLOAT_T> y);

#endif
