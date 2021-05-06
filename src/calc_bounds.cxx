/* Compute theoretical error bounds */
#ifndef CALC_BOUNDS_CXX
#define CALC_BOUNDS_CXX

#include <iostream>
#include <string>
#include <boost/lexical_cast.hpp>

#include "error_semantics.hxx"

#define USAGE ( \
	"calc_bounds <n> <lb> <ub> <var>\n" \
	"Returns string of the form\n" \
	"\treal <var> in [low,high] +/- absolute error\n" \
	"Representing the error of double-precision inner product\n" \
	"which can be used as input to FPTaylor.")
#define FLOAT_T double

FLOAT_T parse_numeric(const char* s);
std::string parse_expr(const char* s);

int main (int argc, char* argv[])
{
	long long n;
	FLOAT_T lb, ub = 0.0;
	if (argc != 5) {
		std::cout << USAGE << std::endl;
		return 1;
	}

	n = atoll(argv[1]);
	if (n <= 0) {
		std::cout << USAGE << std::endl;
		return 1;
	}
	try {
		lb = parse_numeric(argv[2]);
		ub = parse_numeric(argv[3]);
	} catch (int e) {
		std::cout << "bad lb or ub: " << lb << "," << ub << std::endl
			<< USAGE << std::endl;
		return 1;
	}
	std::string var = parse_expr(argv[4]);
	Vec_E<FLOAT_T> x, y;
	Scal_E<FLOAT_T> xdy = Scal_E<FLOAT_T>();
	Scal_E<FLOAT_T> sqrt_x = Scal_E<FLOAT_T>();
	Scal_E<FLOAT_T> rsqrt = Scal_E<FLOAT_T>();
	x = Vec_E<FLOAT_T>(n, lb, ub, 0.0);
	y = Vec_E<FLOAT_T>(n, lb, ub, 0.0);
	xdy = dot_e<FLOAT_T>(x, y);
	sqrt_x = sqrt_e<FLOAT_T>(xdy);
	rsqrt = inv_e<FLOAT_T>(sqrt_x);

	std::cout << "// x, y : " << typeid(FLOAT_T).name()
		<< "^" << n << " in [" << lb << "," << ub << "]" << std::endl;

	std::cout << var << " in ["
		<< xdy.lb() << "," << xdy.ub() << "] +/- "
		<< xdy.error_ub() << std::endl;

	std::cout << var << " in ["
		<< xdy.lb() << "," << xdy.ub() << "] to "
		<< xdy.error_ub()/xdy.ub() / (2*mach_eps<FLOAT_T>) << " ulps" << std::endl;

	// These are incorrect, so leave out for now. FPTaylor or Satire do it better :)
	/* std::cout << "sqrt(x . y) \\in [" */
	/* 	<< sqrt_x.lb() << "," << sqrt_x.ub() << "]" << std::endl; */
	/* std::cout << "abserr(sqrt(x . y)) <= " */
	/* 	<< sqrt_e(xdy).error_ub() << std::endl; */

	/* std::cout << "1/sqrt(x . y) \\in [" */
	/* 	<< rsqrt.lb() << "," << rsqrt.ub() << "]" << std::endl; */
	/* std::cout << "abserr(1/sqrt(x . y)) <= " */
	/* 	<< rsqrt.error_ub() << std::endl; */

	return 0;
}

FLOAT_T parse_numeric(const char* s)
{
	return boost::lexical_cast<FLOAT_T, std::string>(s);
}

std::string parse_expr(const char* s)
{
	return std::string(s);
}

#endif
