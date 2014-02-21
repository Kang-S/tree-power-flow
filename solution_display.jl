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
            candidate = child.candidates[key(p2-d,v)]
            unshift!(q, (candidate, child))
            @printf "%6s %8.2f %5.2f %8.2f\n" child p1 v p2
        end
    end
end

function load_matpower_solution(casefile)
    lines = open(readlines, casefile)
    if lines[1] != "converged\n" error("casefile doesn't look like it converged") end
    i = 1
    while ~ismatch(r"mpc.bus = \[", lines[i]) i += 1 end
    i += 1
    voltages = Dict()
    while ~ismatch(r"\];", lines[i])
        line = split(lines[i])
        bus, v = line[1], line[8]
        bus, v = parseint(bus), parsefloat(v)
        voltages[bus] = v
        i += 1
    end
    while ~ismatch(r"mpc.branch = \[", lines[i]) i += 1 end
    i += 1
    # from_bus, to_bus, from_power, to_power, from_voltage, to_voltage
    list = (Int64,Int64,Float64,Float64,Float64,Float64)[]
    while ~ismatch(r"\];", lines[i])
        line = split(lines[i])
        fbus, tbus, fpower, tpower = line[1], line[2], line[14], line[16]
        fbus, tbus, fpower, tpower = parseint(fbus), parseint(tbus), parsefloat(fpower), parsefloat(tpower)
        fv, tv = voltages[fbus], voltages[tbus]
        # we'll use the convention that from_bus is always less than to_bus
        if fbus < tbus
            push!(list, (fbus,tbus,fpower,tpower,fv,tv))
        else
            push!(list, (tbus,fbus,tpower,fpower,tv,fv))
        end
        i += 1
    end
    sort(list)
end

function matpower_compare(casefile, candidate, root, R2)
    # different format for print_full_solution
    _round(x, p) = round(x/p)*p
    key(p::Float64, v::Float64) = _round(p, R2), v
    q = [(candidate,root)];
    # from_bus, to_bus, from_power, to_power
    list = (Int64,Int64,Float64,Float64,Float64,Float64)[]
    while length(q) > 0
        c,b = pop!(q)
        for i=1:c.n
            child = b.children[i]
            d = child.d
            p1,v,p2 = c.children[:,i]
            candidate = child.candidates[key(p2-d,v)]
            unshift!(q, (candidate, child))
            # we'll use the convention that from_bus is always less than to_bus
            if parseint(b.name) < parseint(child.name)
                push!(list, (parseint(b.name), parseint(child.name), p1, -p2, c.v, v))
            else
                push!(list, (parseint(child.name), parseint(b.name), -p2, p1, v, c.v))
            end
        end
    end
    matpower_list = load_matpower_solution(casefile)
    @printf "%6s %6s %10s %10s %10s %10s %6s %6s %6s %6s\n" "fbus" "tbus" "fp1" "fp2" "tp1" "tp2" "fv1" "fv2" "tv1" "tv2" 
    for (me, matpower) in zip(sort(list), matpower_list)
        assert(me[1] == matpower[1])
        assert(me[2] == matpower[2])
        @printf "%6d %6d %10.1f %10.1f %10.1f %10.1f %6.2f %6.2f %6.2f %6.2f\n" me[1] me[2] me[3] matpower[3] me[4] matpower[4] me[5] matpower[5] me[6] matpower[6]
    end
end
