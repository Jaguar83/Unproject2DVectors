# vim:set ai et shiftwidth=4 softtabstop=4 syntax=python :
import operator as op
from itertools import chain, combinations

fri = chain.from_iterable

theta, phi, psi, A, B, C = var('theta phi psi A B C', domain=RR)
x1y, y1y, z1y = var('x1y y1y z1y', domain=RR)

assume(*fri((
    (v >= 0, v <= 1)
    for v in (A, B, C, x1y, y1y, z1y)
)))

#phi = X rotation
#theta = Y rotation
#psi = Z rotation

rmat = matrix(((cos(theta), sin(theta), 0), (-sin(theta), cos(theta), 0), (0, 0, 1)))

zmat, ymat, xmat = (
    rmat.matrix_from_rows_and_columns(
        *([(range(3)*2)[i:][0:3]]*2)
    ).subs(theta=th)
    for i, th in zip(range(3), (psi, theta, phi))
)

mat = xmat*ymat*zmat

AA = (
    (0.9738402962684631, x1y, 0.2272336333990097, A),
    (-0.47926923632621765, y1y, 0.8776679039001465, B),
    (-0.003990781959146261, -z1y, 0.9999920725822449, C),
)

# Normalise x and z coordinates
x1, y1, z1 = (
    matrix([
        tuple(chain(
            vector((vx, vz)).normalized()
                .pairwise_product(vector((vC, vC))),
            [vy]
        ))
    ]).matrix_from_columns([0, 2, 1])
    for vx, vy, vz, vC in AA
)

x0, y0, z0 = map(matrix, Matrix.identity(3))

x1a, y1a, z1a = (
    vr.subs(vr[0][1]==(v1[0].cross_product(v2[0]))[1])
    for vr, v1, v2 in map(
        ((x1, y1, z1) * 2).__getitem__,
        map(slice, range(3), range(3, 6))
    )
)

result = None

for res in solve([v1[0]*v2[0]==0 for v1, v2 in combinations((x1a, y1a, z1a), 2)], A, B, C):
    if all((
        set(v.left().variables()) <= {A, B, C} and
        len(v.right().variables()) == 0 and
        imag(v.right()) == 0 and
        float(v.right()) >= 0
        for v in res
    )):
        result = [v.left()==float(v.right()) for v in res]
        break

if result is not None:
    result1 = None
    for res in solve([sum((v1^2 for v1 in v.subs(*result)[0]))==1 for v in (x1, y1, z1)], x1y, y1y, z1y):
        if all((
            set(v.left().variables()) <= {x1y, y1y, z1y} and
            len(v.right().variables()) == 0 and
            imag(v.right()) == 0 and
            float(v.right()) >= 0
            for v in res
        )):
            result1 = [v.left()==float(v.right()) for v in res]
            break

    if result1 is not None:
        x1r, y1r, z1r = [v.subs(result + result1) for v in (x1, y1, z1)]
        th = float(-asin(x1r[0][2]))
        ps = atan2(*x1r[0][1::-1])
        ph = atan2(y1r[0][2], z1r[0][2])
        
        print "Radians: phi={}, theta={}, psi={}".format(ph, th, ps)
        print "Degrees: phi={}, theta={}, psi={}".format(
            *map(
                math.degrees,
                (ph, th, ps)
            )
        )
 
