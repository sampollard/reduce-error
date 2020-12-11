// Generate a list of nested parentheses

// TODO: fill in NAME based on associativity
// Make parameterized by n
// Algorithm P from Knuth
object Gen {
  val lb: Double = -1.0
  val ub: Double = 1.0

  def l_assoc(n: Int): String = {
    val varnames = (1 to n).map((i: Int) => "x" + i.toString)
    val rangelb = varnames.mkString("", s" >= $lb && ", s" >= $lb")
    val rangeub = varnames.mkString("", s" <= $ub && ", s" <= $ub")
    val arglist = varnames.mkString("",": Real, ",": Real")
    val definition = s"def sum_${n}_l($arglist): Real = {"
    val precondition = s"require($rangelb &&\n$rangeub)"
    val expr = varnames.mkString("+")
    definition + "\n\t" + precondition + "\n\t" + expr + "\n}"
  }

  def main(args: Array[String]): Unit = {
    val s: String = l_assoc(args(0).toInt)
    println(s)
  }
}

