function pk(;g=1,b=-10,vk=1,vm=1,pm=-1)
    # solve for pk given pm,vk,vm; ignores theta
    temp = b^2*(-pm^2+(2*g*pm+(b^2+g^2)*vk^2)*vm^2-g^2*vm^4)
    temp < 0 ? NaN : 1/(b^2+g^2) * ((-b^2+g^2)*pm+g^3*(vk^2-vm^2)+b^2*g*(vk^2+vm^2)-2*g*temp^.5)
end
function pk_θ(;g=1,b=-10,vk=1,vm=1,pm=-1)
    # solve for pk, θkm given pm,vk,vm
    disc = b^2*(-pm^2+(2*g*pm+(b^2+g^2)*vk^2)*vm^2-g^2*vm^4)
    if disc < 0 
        return NaN, NaN
    end
    pk = 1/(b^2+g^2) * ((-b^2+g^2)*pm+g^3*(vk^2-vm^2)+b^2*g*(vk^2+vm^2)-2*g*disc^.5)
    arg = (-g*pm+g^2*vm^2+disc^.5)/((b^2+g^2)*vk*vm)
    if arg > 1 arg = 1 end
    if arg < -1 arg = -1 end
    temp = -pm^2+(2*g*pm+g^2*vk^2)*vm^2-g^2*vm^4
    θ = temp > 0 ? acos(arg) : -acos(arg)
    pk, θ
end
function check(;g=1,b=-10,vk=1,vm=1,pk=.995,pm=-1,θ=-.1)
    # sanity check after a solution has been found
    pk_hat = g*(vk^2-vk*vm*cos(θ)) + b*vk*vm*sin(θ)
    pm_hat = g*(vm^2-vk*vm*cos(θ)) - b*vk*vm*sin(θ)
    err1 = abs((pk_hat-pk)/pk_hat)
    err2 = abs((pm_hat-pm)/pm_hat)
    maximum([err1, err2])
end

function f1(bus)
    round1(pkm,vm,pm) = _round(pkm, R1)
    for (i,child) in enumerate(bus.children)
        for vk in VRANGE
            d, g, b = child.d, child.g, child.b
            p(c::Candidate) = pk(g=g,b=b,vk=vk,vm=c.v,pm=-(c.p+d))
            raw_flows = filter!(x->!isnan(x[1]), shuffle([(p(c),c.v,c.p+d) for c in values(child.candidates)]))
            if length(raw_flows) > 0
                bus.raw_flows[i][vk] = collect(values([round1(x...)=>x for x in raw_flows]))
            end
        end
        @assert length(bus.raw_flows[i]) > 0
    end
end

product(x,y) = collect([(a,b) for a in x, b in y]);
function f2(bus)
    if length(bus.children) == 0
        for vm in VRANGE
            c = Candidate(vm, 0)
            bus.candidates[key(c)] = c
        end
        return
    end
    if length(bus.children) == 1
        for (vk,raw_flows) in bus.raw_flows[1]
            for raw_flow in raw_flows
                c = Candidate(vk, 1)
                add!(c, 1, [raw_flow...])
                bus.candidates[key(c)] = c
            end
        end
        return
    end
    for vk in VRANGE
        pairs = shuffle(product(bus.raw_flows[1][vk], bus.raw_flows[2][vk]))
        candidates = Dict()
        for (b1, b2) in pairs
            c = Candidate(vk, length(bus.children))
            add!(c, 1, [b1...])
            add!(c, 2, [b2...])
            candidates[key(c)] = c
        end
        the_rest = [x[vk] for x in bus.raw_flows[3:]]
        for (i,raw_flows) in enumerate(the_rest)
            pairs = shuffle(product(values(candidates), raw_flows))
            candidates = Dict()
            for (candidate, next_bus) in pairs
                #n += 1
                new = add(candidate, i+2, [next_bus...])
                candidates[key(new)] = new
            end
        end
        merge!(bus.candidates, candidates)
    end
    #bus.raw_flows = [Dict() for child in bus.children]
end

function f3!(bus)
    f1(bus)
    f2(bus)
end
function run_algo(buses)
    for i=length(buses):-1:1
        print(buses[i], ' ')
        f3!(buses[i])
        println(length(buses[i].candidates))
    end
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
function check_all(bus_list)
    maximum(map(check_bus, bus_list))
end;
