import sys
import mosek.fusion
from mosek.fusion import *
from mosek.array import *

foods  = ["bagels", "muffins"]
c = [5.,4,3] # prices
A = DenseMatrix([ [2.,3,1], [4.,1,2], [3.,4,2] ])
b = [5.,11,8]
n = len(c)

def main(args):
  with Model('alan') as M:
    x = M.variable("x", n, Domain.greaterThan(0.0))
    M.objective("cost", ObjectiveSense.Maximize, Expr.dot(c,x))
    M.constraint("ingredients",  Expr.mul(A, x), Domain.lessThan(b)) # sum protein at least 4.0
    M.setLogHandler(sys.stdout)
    M.solve()
    print(x.level())

if __name__ == '__main__':
  main(sys.argv[1:])
