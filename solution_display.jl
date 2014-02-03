function pretty(bus, candidates; start=1, stop=5)
    name = bus.name
    @printf "%7s %7s " "p$name" "v$name"
    for child in bus.children
        cname = child.name
        both = @sprintf "%s_%s" name cname
        @printf "%7s %7s %7s " "p$both" "v$cname" "p$cname"
    end
    println()

    for candidate in candidates[start:stop]
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

function print_full_solution(candidate, root)
    # breadth first search the tree, finding the correct (p,v) at each child
    # from the candidate of the parent
    @printf "%6s %7.3f %7.3f\n" root candidate.p candidate.v
    q = [(candidate,root)];
    while length(q) > 0
        c,b = pop!(q)
        for i=1:c.n
            child = b.children[i]
            d = child.d
            p1,v,p2 = c.children[:,i]
            candidate = child.candidates[key(p2-d,v)]
            unshift!(q, (candidate, child))
            @printf "%6s %7.3f %7.3f %7.3f\n" child p1 v p2
        end
    end
end
