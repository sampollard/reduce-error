// Generate a list of nested parentheses

// TODO: fill in NAME based on associativity
// Make parameterized by n
// Algorithm P from Knuth
object Gen {
  val n: Int = 4
  val varnames: Array[String] = Array("x1","x2","x3")

  val lb: Double = -1.0
  val ub: Double = 1.0

  val rangelb = varnames.mkString("", s">=$lb && ", s">=$lb")
  val rangeub = varnames.mkString("", s"<=$ub && ", s"<=$lb")
  val arglist = varnames.mkString("",": Real, ",": Real")
  val definition = s"def sum_NAME($arglist): Real = {"
  val precondition = s"require($rangelb && $rangeub)"
  val expr = varnames.mkString("+")

  def main(args: Array[String]): Unit = {
    println(definition + "\n\t" + precondition + "\n\t" + expr + "\n}")
  }
}

