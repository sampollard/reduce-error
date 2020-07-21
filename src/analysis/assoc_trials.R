# Compute different combinatorial sequences
set.seed(42)
n <- 15
N <- seq(n)
# Catalan numbers
C_n <- factorial(2*N) / (factorial(N+1) * factorial(N))
# What I thought was the right value for total permutations
rho_n <- factorial(2*N) / (factorial(N+1) * 2^(N-1))
com <- data.frame(n = N, fact_n = factorial(N), C_n = C_n, rho_n = rho_n)
format(com, scientific = FALSE)

# Algorithm W
worm_walk <- function(A, op = "+") {
	n <- length(A) - 1
	p <- n
	q <- n
	s <- character(0)
	i <- 1
	while (q != 0) {
		# 0 <= x < (q+p)(q-p+1)
		x <- sample.int((q+p)*(q-p+1), size=1) - 1
		if (x < (q+1)*(q-p)) {
			q <- q - 1
			if (s[length(s)] == "(") {
				s <- c(s,A[i],op,A[i+1])
				i <- i + 2
			}
			s <- c(s,")")
		} else {
			p <- p - 1
			if (length(s) > 0 && s[length(s)] == ")") {
				s <- c(s,op)
			}
			s <- c(s,"(")
		}
	}
	cat("i = ", i)
	return(s)
}
# Just to see how it looks
s <- worm_walk(rep("_",8))
paste0(s, collapse = "")
# Actual evaluation
A <- runif(20)
v <- worm_walk(A,op = "+")
paste0(v, collapse = "")
# Problem  is it keeps generating too many NAs at the end. But only sometimes.
# (((((((0.630405408097431+0.66851892718114)))+(0.991805712459609+0.693499072920531)+(0.716757451649755+0.888285282766446))+(0.802068764809519+0.0825222264975309)+((0.27807461284101+0.113545959349722)+(0.14250398078002+0.401909028878435))+((0.695935413008556+0.477118747541681))+(0.444960728753358+0.925861074822024))))+(0.247804617509246+0.70332307741046)+((0.696654206607491+0.961895964108407)+(NA+NA))

# Here’s a puzzle for everyone. Suppose you are generating a bunch of different permutations and parenthesizations (I call them associations) of an array A with n elements. For example, say n=4 and A = [a,b,c,d]. Some examples are
# ((ab)c)d, (ab)(cd), d((ac)b),
# Let’s call R_n = the number of ways to do this. Your first (warmup) question is: what is R_n?
# Next, suppose the concatenation operator is associative but not commutative. Now what is V_n, where V_n is the potential number of values you can get, given that ab = ba but (a(bc)) != (ab)c? It can be manually checked pretty easily that V_1 = 1, V_2 = 1, V_3 = 3.

df <- read.table(file = 'file.tsv', sep = '\t', header = TRUE)

