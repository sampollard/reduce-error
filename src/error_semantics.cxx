#ifndef ERROR_SEMANTICS_CXX
#define ERROR_SEMANTICS_CXX

#include "error_semantics.hxx"

/* Scalars */
template <class FLOAT_T, class MPFR_T>
Scal_E<FLOAT_T, MPFR_T>::Scal_E() { };

template <class FLOAT_T, class MPFR_T>
Scal_E<FLOAT_T, MPFR_T>::~Scal_E() { };

// Fill concrete value and give upper/lower bounds
template <class FLOAT_T, class MPFR_T>
Scal_E<FLOAT_T, MPFR_T>::Scal_E(FLOAT_T x, FLOAT_T lb, FLOAT_T ub)
	: data_(x), lb_(lb), ub_(ub)
{
	inf_norm_ = std::max(abs(lb),abs(ub));
}

// Don't fill vector, just do symbolic computations
/* TODO */
template <class FLOAT_T, class MPFR_T>
Scal_E<FLOAT_T, MPFR_T>::Scal_E(FLOAT_T lb, FLOAT_T ub, MPFR_T error)
	: lb_(lb), ub_(ub)
{
	inf_norm_ = std::max<FLOAT_T>(abs(lb), abs(ub));
}

template <class FLOAT_T, class MPFR_T>
long long Scal_E<FLOAT_T, MPFR_T>::length() { return 1LL; };

template <class FLOAT_T, class MPFR_T>
FLOAT_T Scal_E<FLOAT_T, MPFR_T>::lb() { return lb_; }

template <class FLOAT_T, class MPFR_T>
FLOAT_T Scal_E<FLOAT_T, MPFR_T>::ub() { return ub_; }

template <class FLOAT_T, class MPFR_T>
MPFR_T Scal_E<FLOAT_T, MPFR_T>::error_lb() { return error_lb_; }

template <class FLOAT_T, class MPFR_T>
MPFR_T Scal_E<FLOAT_T, MPFR_T>::error_ub() { return error_ub_; }

/* Vectors */
template <class FLOAT_T, class MPFR_T>
Vec_E<FLOAT_T, MPFR_T>::Vec_E() { };

template <class FLOAT_T, class MPFR_T>
Vec_E<FLOAT_T, MPFR_T>::~Vec_E() { };

// Fill vector with upper/lower bounds
template <class FLOAT_T, class MPFR_T>
Vec_E<FLOAT_T, MPFR_T>::Vec_E(FLOAT_T *x, long long n, FLOAT_T lb, FLOAT_T ub)
	: n_(n), lb_(lb), ub_(ub)
{
	data_.reserve(n);
	for (long long i = 0; i < n; i++) {
		data_[i] = x[i];
	}
	inf_norm_ = std::max(abs(lb),abs(ub));
}

// Don't fill vector, just do symbolic computations
template <class FLOAT_T, class MPFR_T>
Vec_E<FLOAT_T, MPFR_T>::Vec_E(long long n, FLOAT_T lb, FLOAT_T ub)
	: n_(n), lb_(lb), ub_(ub)
{
	inf_norm_ = std::max(abs(lb),abs(ub));
}

template <class FLOAT_T, class MPFR_T>
long long Vec_E<FLOAT_T, MPFR_T>::length() { return n_; };

template <class FLOAT_T, class MPFR_T>
FLOAT_T Vec_E<FLOAT_T, MPFR_T>::lb() { return lb_; }

template <class FLOAT_T, class MPFR_T>
FLOAT_T Vec_E<FLOAT_T, MPFR_T>::ub() { return ub_; }

template <class FLOAT_T, class MPFR_T>
MPFR_T Vec_E<FLOAT_T, MPFR_T>::error_lb() { return error_lb_; }

template <class FLOAT_T, class MPFR_T>
MPFR_T Vec_E<FLOAT_T, MPFR_T>::error_ub() { return error_ub_; }

/* Vector operations */
MPFR_T_DEFAULT gamma(const std::type_info& float_t, long long int n)
{
	MPFR_T_DEFAULT eps;
	if (typeid(float_t) == typeid(double)) {
		eps = mach_eps<double>;
	} else if (typeid(float_t) == typeid(float)) {
		eps = mach_eps<float>;
	} else {
		std::cerr << "gamma: unsupported floating-point type "
			<< typeid(float_t).name() << std::endl;
		std::cout << "Expected something like " << typeid(double).name() << std::endl;
		throw(ANALYSIS_EXCEPTION);
	}
	return n * eps / (1.0 - n * eps);
}

template <typename FLOAT_T>
Scal_E<FLOAT_T> dot_e(Vec_E<FLOAT_T> x, Vec_E<FLOAT_T> y)
{
	/* TODO: Allow for different floating-point types in return-value and input. */
	long long n = x.length();
	assert(x.length() == y.length());
	MPFR_T_DEFAULT mach_del;
	if (typeid(FLOAT_T) == typeid(double)) {
		mach_del = mach_del_dbl;
	} else if (typeid(FLOAT_T) == typeid(float)) {
		mach_del = mach_del_flt;
	} else {
		std::cerr << "dot_e: unsupported type "
			<< typeid(FLOAT_T).name() << std::endl;
		throw(ANALYSIS_EXCEPTION);
	}
	MPFR_T_DEFAULT err;
	FLOAT_T lb, ub;
	std::vector<FLOAT_T> range = std::vector<FLOAT_T>(4);
	std::vector<FLOAT_T> abs_range = std::vector<FLOAT_T>(4);
	range[0] = x.lb() * y.lb();
	range[1] = x.lb() * y.ub();
	range[2] = x.ub() * y.lb();
	range[3] = x.ub() * y.ub();
	lb = *std::min_element(range.begin(), range.end());
	ub = *std::max_element(range.begin(), range.end());
	abs_range[0] = abs(x.lb());
	abs_range[1] = abs(x.ub());
	abs_range[2] = abs(y.lb());
	abs_range[3] = abs(y.ub());
	FLOAT_T mag = *std::max_element(abs_range.begin(), abs_range.end());

	/*  e * |x| . |y| * \gamma_n + nd(1 + \theta_{n-1}) */
	err = x.error_ub() + y.error_lb()
		+ mag * mag * n * gamma(typeid(FLOAT_T), n)
		+ n * mach_del * (1.0 + gamma(typeid(FLOAT_T), n-1));
	return Scal_E<FLOAT_T>(n * lb, n * ub, err);
}


/* Explicit template instantiation. */
template class Vec_E< double, mpfr_float_1000 >;
template class Vec_E< float, mpfr_float_1000 >;
template class Scal_E< double, mpfr_float_1000 >;
template class Scal_E< float, mpfr_float_1000 >;
template Scal_E<float> dot_e(Vec_E<float> x, Vec_E<float> y);
template Scal_E<double> dot_e(Vec_E<double> x, Vec_E<double> y);
#endif