/* Compute theoretical error bounds */
#ifndef CALC_BOUNDS_CXX
#define CALC_BOUNDS_CXX

#include <iostream>
#include <string>
#include <boost/lexical_cast.hpp>

#include "error_semantics.hxx"

#define USAGE ("bounds <n> <lb> <ub> expr")
#define FLOAT_T double

FLOAT_T parse_numeric(const char* s);
void parse_expr(const char* s);

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
	parse_expr(argv[4]);
	Vec_E<FLOAT_T> x, y;
	Scal_E<FLOAT_T> xdy = Scal_E<FLOAT_T>();
	x = Vec_E<FLOAT_T>(n, lb, ub);
	y = Vec_E<FLOAT_T>(n, lb, ub);
	xdy = dot_e<FLOAT_T>(x, y);

	std::cout << "x_i and y_i \\in [" << lb << "," << ub << "]" << std::endl;
	std::cout << "ae(x . y) <= " << xdy.error_ub() << std::endl;

	return 0;
}

FLOAT_T parse_numeric(const char* s)
{
	return boost::lexical_cast<FLOAT_T, std::string>(s);
}

void parse_expr(const char* s)
{
	return;
}

#endif
