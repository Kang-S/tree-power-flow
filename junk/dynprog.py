from numpy import linspace, concatenate as cat, pi, sin
from loadfiles import loadcase
from itertools import product

VSET = cat((linspace(.5, 1, 50, endpoint=False), linspace(1, 6, 51)))
THETASET = linspace(-pi, pi, 100)

class Bus:
    def __init__(self, ID, d, vhat, theta_hat, parent, children, b, g):
        v, theta = 1, 0 # actual voltage
        self.ID = ID
        self.d = d # demand
        self.vhat = vhat # target voltage magnitude
        self.theta_hat = theta_hat # target voltage angle
        self.parent = parent
        self.children = children
        self.b = b # susceptance of line connecting parent to self
        self.g = g # conductance of line connecting parent to self
        # alpha - penalty for voltage mismatch

def base_case(root):
    def solve_children(root):
        for child in root.children:
            #for v, theta in product(VSET, THETASET):
            #    child.v, child.theta = v, theta
            #    pass
            v1 = root.v
            p2 = -child.d
            b, g = child.b, child.g 
            if g == 0:
                child.theta = pi/50
                child.v = -p2/(b*v1*sin(child.theta))
            else:
                child.theta = 0
                child.v = .5*(v1+(v1*v1+4*p2/g)**.5) # will fail for v1 too small
        pass
    for v, theta in product(VSET, THETASET):
        root.v, root.theta = v, theta
        solve_children(root)
        pass

# maybe use data structures from CCOPF?
def test1():
    #bus, branch, Bbus = loadcase('case_base.m')
    #G = Bus(0, 0, 1, 0, None, [1,2,3], None, None)
    #L1 = Bus(1, 1, 1, 0, 0, None, .1, .01)
    #L2 = Bus(2, 1, 1, 0, 0, None, .1, .01)
    #L3 = Bus(3, 1, 1, 0, 0, None, .1, .01)
    #buses = [G, L1, L2, L3]

    #base_case(G)

if __name__ == '__main__':
    test1()
