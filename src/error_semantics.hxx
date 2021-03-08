/* Semantics of floating-point error.
 * Given an operation, return the error bounds.
 */
#ifndef ERROR_SEMANTICS_HXX
#define ERROR_SEMANTICS_HXX

#include <limits>
#include <boost/multiprecision/mpfr.hpp>
#include <boost/multiprecision/number.hpp>

using namespace boost::multiprecision;
using namespace boost::math;

#define MPFR_T_DEFAULT mpfr_float_1000

template <typename FLOAT_T>
const MPFR_T_DEFAULT mach_eps = std::numeric_limits<FLOAT_T>::epsilon();

const MPFR_T_DEFAULT mach_eps_flt = mach_eps<float>;
const MPFR_T_DEFAULT mach_eps_dbl = mach_eps<double>;

const MPFR_T_DEFAULT mach_del_flt =
	pow(2, std::numeric_limits<float>::min_exponent - 1)*mach_eps<float>;
const MPFR_T_DEFAULT mach_del_dbl =
	pow(2, std::numeric_limits<double>::min_exponent - 1)*mach_eps<double>;

MPFR_T_DEFAULT dot_e(double mag, long long int n, MPFR_T_DEFAULT e);

template <class FLOAT_T, class MPFR_T>
class Vec_E {
	public:
		// Empty constructor
		Vec_E();
		// Fill vector
		// Vec_E(long long n, FLOAT_T* x);
		// Fill vector with upper/lower bounds
		Vec_E(long long n, FLOAT_T ub, FLOAT_T lb, FLOAT_T* x);
		// Don't fill vector, just do symbolic computations
		// Destructor
		~Vec_E();
		long long length();
		MPFR_T error_ub();
		MPFR_T error_lb();
	private:
		std::vector<FLOAT_T> data_;
		MPFR_T ub_;
		MPFR_T lb_;
		MPFR_T mag_;
		MPFR_T error_ub_;
		MPFR_T error_lb_;
		MPFR_T error_abs_;
};

#endif
