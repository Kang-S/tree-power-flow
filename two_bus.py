from math import sqrt

class two_bus:
    def __init__(self, g, b, p2, v1=1, L=.9, U=1.1):
        self.g = g
        self.b = b
        self.p2 = p2
        self.v1 = v1
        self.L = L
        self.U = U
    def e1(self, e2, f2):
        b, g, p2 = self.b, self.g, self.p2
        return (g*(e2**2+f2**2)-p2)/(g*e2+b*f2)
    def p1(self, e2, f2):
        pass
    def e2(self, e1, p1):
        b, g, p2 = self.b, self.g, self.p2
        A = g*(b**2+g**2)*e1**2-g**2*p1
        try:
            B = b*sqrt(g*(-g*p1**2+(b**2+g**2)*e1**2*(p1+p2)))
        except ValueError:
            return np.inf, np.inf
        C = g*(b**2+g**2)*e1
        return (A+B)/C, (A-B)/C
    def f2(self, e1, p1):
        b, g, p2 = self.b, self.g, self.p2
        A = b*p1
        try:
            B = sqrt(g*(-g*p1**2+(b**2+g**2)*e1**2*(p1+p2)))
        except ValueError:
            return np.inf, np.inf
        C = (b**2+g**2)*e1
        return (A+B)/C, (A-B)/C
    def search(self):
        n = 100
        p = np.empty((n,n))
        e = np.empty((n,n))
        cost1 = np.empty((n,n))
        cost2 = np.empty((n,n))
        for i,p1 in enumerate(np.linspace(self.L,self.U,n)):
            for j,e1 in enumerate(np.linspace(self.L,self.U,n)):
                e2,e2_2 = self.e2(e1,p1)
                f2,f2_2 = self.f2(e1,p1)
                v1_1,v1_2 = ef2v(e2,f2), ef2v(e2_2, f2_2)
                p[i][j] = p1
                e[i][j] = e1
                cost1[i][j] = (v1_1-self.v1)**2
                cost2[i][j] = (v1_2-self.v1)**2
        i1 = np.unravel_index(cost1.argmin(), (n,n))
        i2 = np.unravel_index(cost2.argmin(), (n,n))
        return (p[i1],e[i1]), (p[i2],e[i2])
