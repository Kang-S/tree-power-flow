using CandidateModule
using BusModule
include("basics.jl")

function run_algo(buses, N, R1, R2, vhat=1.0)

    # round 'to the p' place... e.g. if p=.2, _round(1.12) = 1.2 and _round(1.08) = 1.0
    # TODO: experiment -- make the key an integer
    _round(x, p) = round(x/p)*p
    key(c) = _round(c.p, R2), c.v
    VRANGE = linspace(.8,1.2,N)
    sort!(VRANGE, by = x->abs(vhat-x))

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

    product(x,y) = collect([(a,b) for a in x, b in y])

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
            if !haskey(bus.raw_flows[1], vk)
                continue
            end
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

    # for the non-root buses we collect solutions for all voltages
    for i=length(buses):-1:2
        print(buses[i], ' ')
        f1(buses[i])
        f2(buses[i])
        println(length(buses[i].candidates))
    end

    # for the root, we look for solutions close to vhat and stop once we find 
    # a voltage that gives solutions
    print(buses[1], ' ')
    function f1root(bus)
        round1(pkm,vm,pm) = _round(pkm, R1)
        for vk in VRANGE
            for (i,child) in enumerate(bus.children)
                d, g, b = child.d, child.g, child.b
                p(c::Candidate) = pk(g=g,b=b,vk=vk,vm=c.v,pm=-(c.p+d))
                raw_flows = filter!(x->!isnan(x[1]), shuffle([(p(c),c.v,c.p+d) for c in values(child.candidates)]))
                if length(raw_flows) > 0
                    bus.raw_flows[i][vk] = collect(values([round1(x...)=>x for x in raw_flows]))
                end
            end
            # check if there is at least one raw_flow per child at this voltage
            exists_flow = [length(bus.raw_flows[i][vk])>0 for i=1:length(bus.children)]
            if all(exists_flow)
                return
            end
        end
        @assert false # didn't find a solution at the root
    end
    f1root(buses[1])
    f2(buses[1])
    println(length(buses[1].candidates))
end;
