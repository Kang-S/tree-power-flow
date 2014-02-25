include("basics.jl")

function check(;g=1,b=-10,vk=1,vm=1,pk=.995,pm=-1,θ=-.1)
    # sanity check after a solution has been found
    pk_hat = g*(vk^2-vk*vm*cos(θ)) + b*vk*vm*sin(θ)
    pm_hat = g*(vm^2-vk*vm*cos(θ)) - b*vk*vm*sin(θ)
    err1 = abs(pk_hat) > 1e-4 ? abs((pk_hat-pk)/pk_hat) : abs(pk_hat-pk)
    err2 = abs(pm_hat) > 1e-4 ? abs((pm_hat-pm)/pm_hat) : abs(pm_hat-pm)
    maximum([err1, err2])
end

function check2(;g=1,b=-10,vk=1,vm=1,pk=.995,pm=-1,θ=-.1)
    # sanity check after a solution has been found
    pk_hat = g*(vk^2-vk*vm*cos(θ)) + b*vk*vm*sin(θ)
    pm_hat = g*(vm^2-vk*vm*cos(θ)) - b*vk*vm*sin(θ)
    err1 = abs(pk_hat) > 1e-4 ? abs((pk_hat-pk)/pk_hat) : abs(pk_hat-pk)
    err2 = abs(pm_hat) > 1e-4 ? abs((pm_hat-pm)/pm_hat) : abs(pm_hat-pm)
    err1, err2, pk_hat, pm_hat
end

function check_candidate(bus, candidate)
    function check_child(i)
        child = candidate.children[:,i]
        g = bus.children[i].g
        b = bus.children[i].b
        vk = candidate.v
        pkm, vm, d = child;
        pkm2, θ = pk_θ(g=g, b=b, vk=vk,vm=vm,pm=-d)
        check(g=g, b=b, pk=pkm, vk=vk, pm=-d, vm=vm, θ=θ)
    end
    candidate.n == 0 ? 0 : maximum(map(check_child, 1:candidate.n))
end

function check_bus(bus)
    cc(x) = check_candidate(bus, x)
    maximum(map(cc, values(bus.candidates)))
end

function check_all(root::Bus)
    error_list = Float64[]
    function DFS(bus)
        for child in bus.children
            DFS(child)
        end
        err = check_bus(bus)
        if err > 1e-4 println(bus, ' ', err) end
        push!(error_list, err)
    end
    DFS(root)
    maximum(error_list)
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
    list = (Int64,Int64,Float64,Float64,Float64,Float64,Float64,Float64)[]
    while ~ismatch(r"\];", lines[i])
        line = split(lines[i])
        fbus, tbus, r, x, fpower, tpower = line[1], line[2], line[3], line[4], line[14], line[16]
        fbus, tbus, r, x, fpower, tpower = parseint(fbus), parseint(tbus), parsefloat(r), parsefloat(x), parsefloat(fpower), parsefloat(tpower)
        g, b = r/(r^2+x^2), -x/(r^2+x^2)
        fv, tv = voltages[fbus], voltages[tbus]
        # we'll use the convention that from_bus is always less than to_bus
        if fbus < tbus
            push!(list, (fbus,tbus,fpower,tpower,fv,tv,g,b))
        else
            push!(list, (tbus,fbus,tpower,fpower,tv,fv,g,b))
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

function matpower_check(branch)
    pkm, pm, vk, vm, g, b = branch[3:end]
    pkm2, θ = pk_θ(g=g, b=b, vk=vk,vm=vm,pm=pm)
    check(g=g, b=b, pk=pkm, vk=vk, pm=pm, vm=vm, θ=θ)
end

function matpower_check_all(casefile)
    branches = load_matpower_solution(casefile)
    maximum([matpower_check(branch) for branch in branches])
end;