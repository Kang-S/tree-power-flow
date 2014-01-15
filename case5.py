from numpy import sqrt, cos, sin, arccos, arctan2, nan, pi

def check(b,g,pk,pm,vk,vm,t,tol=1e-4):
    ''' equation 1. Used as a sanity check after the solution has been found. '''
    t *= pi/180
    pk_hat = g*(vk**2-vk*vm*cos(t)) + b*vk*vm*sin(t)
    pm_hat = g*(vm**2-vk*vm*cos(t)) - b*vk*vm*sin(t)
    err1 = abs((pk_hat-pk)/pk_hat)
    err2 = abs((pm_hat-pm)/pm_hat)
    return max([err1, err2])
def em_fm(b, g, pm, ek, pk):
    ''' equation 2 '''
    try:
        temp = sqrt(g*(-g*pk**2+(b**2+g**2)*ek**2*(pk+pm)))
    except ValueError:
        return nan, nan
    A = g*(b**2+g**2)*ek**2-g**2*pk
    B = b*temp
    C = g*(b**2+g**2)*ek
    em = (A+B)/C 
    A = b*pk
    B = temp
    C = (b**2+g**2)*ek
    fm = (A+B)/C 
    return em, fm
def vm_t(b, g, pm, ek, pk):
    ''' convert equation 2 solution to polar coordinates '''
    em, fm = em_fm(b, g, pm, ek, pk)
    return sqrt(em**2+fm**2), arctan2(fm, em)
def pk_t(g,b,vk,vm,pm):
    ''' equation 3 '''
    try:
        temp = sqrt(b**2*(-pm**2+(2*g*pm+(b**2+g**2)*vk**2)*vm**2-g**2*vm**4))
    except ValueError:
        return nan, nan
    t = -arccos((-g*pm+g**2*vm**2+temp)/((b**2+g**2)*vk*vm))
    pk = 1/(b**2+g**2) * ((-b**2+g**2)*pm+g**3*(vk**2-vm**2)+b**2*g*(vk**2+vm**2)-2*g*temp)
    return pk, t
def line01(candidate, d1):
    pk,vk,vm,t = [candidate[k] for k in ['p01','v0','v1','t1']]
    pm = -d1
    return pk,pm,vk,vm,t
def line02(candidate, d2):
    pk,vk,vm,t = [candidate[k] for k in ['p02','v0','v2','t2']]
    p23 = candidate['p23']
    p24 = candidate['p24']
    pm = -(d2+p23+p24)
    return pk,pm,vk,vm,t
def line23(candidate, d3):
    pk,vk,vm,t = [candidate[k] for k in ['p23','v2','v3','t3']]
    pm = -d3
    return pk,pm,vk,vm,t
def line24(candidate, d4):
    pk,vk,vm,t = [candidate[k] for k in ['p24','v2','v4','t4']]
    pm = -d4
    return pk,pm,vk,vm,t
def all_lines(x, d1=1, d2=1, d3=1, d4=1): # x is a candidate solution
    return line01(x,d1), line02(x,d2), line23(x,d3), line24(x,d4)
def check_all_lines(candidate, b=1, g=1, **kwargs):
    return max(check(b,g,*line) for line in all_lines(candidate, **kwargs))
