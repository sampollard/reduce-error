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

template <typename FLOAT_T>
const mpfr_float_1000 mach_eps = std::numeric_limits<FLOAT_T>::epsilon();

const mpfr_float_1000 mach_eps_flt = mach_eps<float>;
const mpfr_float_1000 mach_eps_dbl = mach_eps<double>;

const mpfr_float_1000 mach_del_flt = pow(2, std::numeric_limits<float>::min_exponent - 1)*mach_eps<float>;
const mpfr_float_1000 mach_del_dbl = pow(2, std::numeric_limits<double>::min_exponent - 1)*mach_eps<double>;

mpfr_float_1000 dot_e(double mag, long long int n, mpfr_float_1000 e);

#endif
