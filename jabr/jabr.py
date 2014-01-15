import mosek.fusion
from mosek.fusion import *
from mosek.array import *
from sys import stdout
from math import sqrt

def z2y(r, x):
    ''' converts impedance Z=R+jX to admittance Y=G+jB '''
    return r/(r**2+x**2), -x/(r**2+x**2)

r, x = .02, .2 # impedance and resistance, from matpower
g, b = z2y(r, x) # convert to susceptance and conductance
A = DenseMatrix([ [0., g*sqrt(2),-g,-b], [0, -b*sqrt(2),-b,-g] ])
rhs = [-1.,0]

with Model('jabr') as M:
    u = M.variable("u", 2, Domain.greaterThan(0.0))
    R = M.variable("R", 1, Domain.greaterThan(0.0))
    I = M.variable("I", 1, Domain.unbounded())
    x = Expr.vstack(u,R,I)
    M.objective("maxRsum", ObjectiveSense.Maximize, R)
    M.constraint("u0",  u.index(0).asExpr(), Domain.equalsTo(1/sqrt(2)))
    M.constraint("flow",  Expr.mul(A, x), Domain.equalsTo(rhs))
    M.constraint("cone", x, Domain.inRotatedQCone())
    M.setLogHandler(stdout) 
    M.solve()
    print(u.level())
    print(R.level())
    print(I.level())
