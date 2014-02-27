function pretty(bus, candidates; start=1, stop=5, R2=0)
    name = bus.name
    @printf "%7s %7s %7s " "key" "p$name" "v$name"
    #@printf "%7s %7s " "p$name" "v$name"
    for child in bus.children
        cname = child.name
        both = @sprintf "%s_%s" name cname
        @printf "%7s %7s %7s " "p$both" "v$cname" "p$cname"
    end
    println()

    _round(x, p) = round(x/p)*p
    key(c) = _round(c.p, R2), c.v
    for candidate in candidates[start:stop]
        k = R2 > 0 ? key(candidate) : 0
        @printf "%7.2f " k[1]
        @printf "%7.2f " candidate.p
        @printf "%7.2f " candidate.v
        for i = 1:candidate.n
            child = candidate.children[:,i]
            @printf "%7.2f %7.2f %7.2f " child[1] child[2] child[3]
        end
        println()
    end
end

function dump(bus) # to csv, for python comparison
    m = length(bus.candidates)
    n = 2 + 3*length(bus.children)
    A = Array(Float64, m, n)
    for (i,candidate) in enumerate(values(bus.candidates))
        A[i,1] = candidate.p
        A[i,2] = candidate.v
        for j = 1:candidate.n
            child = candidate.children[:,j]
            A[i,3+3*(j-1)] = child[1]
            A[i,4+3*(j-1)] = child[2]
            A[i,5+3*(j-1)] = child[3]
        end
    end
    writecsv("julia.csv", A)
end

function print_full_solution(candidate, root, R2)
    # breadth first search the tree, finding the correct (p,v) at each child
    # from the candidate of the parent
    _round(x, p) = round(x/p)*p
    key(p::Float64, v::Float64) = _round(p, R2), v
    @printf "%6s %8s %5.2f %8.2f\n" root '-' candidate.v candidate.p 
    q = [(candidate,root)];
    while length(q) > 0
        c,b = pop!(q)
        for i=1:c.n
            child = b.children[i]
            d = child.d
            p1,v,p2 = c.children[:,i]
            cand = child.candidates[key(p2-d,v)]
            unshift!(q, (cand, child))
            @printf "%6s %8.2f %5.2f %8.2f\n" child p1 v p2
        end
    end
end