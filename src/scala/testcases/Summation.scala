// Testing of different summations orders and how far we can push Daisy, in its
// embedded DSL for error analysis.
import daisy.lang._
import Real._


object Summation {

  def dotprod(x1: Real, x2: Real, y1: Real, y2: Real): Real = {
    require(x1 >= -1.0 && x1 <= 1.0 &&
            x2 >= -1.0 && x2 <= 1.0 &&
            y1 >= -1.0 && y1 <= 1.0 &&
            y2 >= -1.0 && y2 <= 1.0)
    x1 * y1 + x2 * y2
  }

  def sum_l(x1 : Real, x2: Real, x3: Real, x4: Real): Real = {
    require(x1 >= -1.0 && x1 <= 1.0 &&
            x2 >= -1.0 && x2 <= 1.0 &&
            x3 >= -1.0 && x3 <= 1.0 &&
            x4 >= -1.0 && x4 <= 1.0)
    x1 + x2 + x3 + x4
  }

  def sum_bin(x1 : Real, x2: Real, x3: Real, x4: Real): Real = {
    require(x1 >= -1.0 && x1 <= 1.0 &&
            x2 >= -1.0 && x2 <= 1.0 &&
            x3 >= -1.0 && x3 <= 1.0 &&
            x4 >= -1.0 && x4 <= 1.0)
    (x1 + x2) + (x3 + x4)
  }

}

