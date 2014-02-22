import Logging: Logging, DEBUG, debug, info, err
Logging.configure(level=DEBUG, filename="log.txt")
using CandidateModule
using BusModule
include("basics.jl")

function num_raw_flows(bus)
    n = 0
    for child in bus.raw_flows
        for raw_flows in values(child)
            n += length(raw_flows)
        end
    end
    n
end

function run_algo(root, N, R1, R2; vhat=1.0, verbose=false, vmin=.8, vmax=1.2)

	total_time = 0
    tic()
    info("ALGO STARTING with root=$root, N=$N, R1=$R1, R2=$R2, vhat=$vhat, verbose=$verbose, vmin=$vmin, vmax=$vmax")

    # round 'to the p place'... e.g. for p=.2 _round(1.08) = 1.0 and _round(1.12) = 1.2 
    _round(x, p) = round(x/p)*p
    key(c) = _round(c.p, R2), c.v
    product(x,y) = collect([(a,b) for a in x, b in y])
    VRANGE = linspace(vmin,vmax,N)
    sort!(VRANGE, by = x->abs(vhat-x))

    function compute_raw_flows(bus, i, vk)
    	child = bus.children[i]
        d, g, b = child.d, child.g, child.b
        function rf(c::Candidate) 
        	pkm = pk(g=g,b=b,vk=vk,vm=c.v,pm=-(c.p+d))
        	vm = c.v
        	pm = c.p+d
        	pkm, vm, pm
        end
        raw_flows = map(rf, values(child.candidates))
        filter!(x->!isnan(x[1]), raw_flows)
        shuffle!(raw_flows)
        # keep only one solution per bucket of size R1
        collect(values([_round(x[1],R1)=>x for x in raw_flows]))
    end

    # TODO: the root/non-root bus split could be changed to generator/non-generator

    # for the non-root buses we collect solutions for all voltages
    function f1(bus)
        for (i,child) in enumerate(bus.children)
            for vk in VRANGE
                bus.raw_flows[i][vk] = compute_raw_flows(bus, i, vk)
            end
            # error out if there isn't at least one raw_flow for this child
            exists_flow = [length(bus.raw_flows[i][vk])>0 for vk in VRANGE]
            if !any(exists_flow) error("no solution at $bus") end
        end
    end

    # for the root, we look for solutions close to vhat and stop once we find 
    # a voltage that gives solutions
    function f1root(bus)
        for vk in VRANGE
            for (i,child) in enumerate(bus.children)
                root.raw_flows[i][vk] = compute_raw_flows(root, i, vk)
            end
            # return if there is at least one raw_flow per child at this voltage
            exists_flow = [length(bus.raw_flows[i][vk])>0 for i=1:length(bus.children)]
            if all(exists_flow) return end
        end
        error("no solution at root ($root)")
    end
    
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
                    add!(c, 1, collect(raw_flow))
                    bus.candidates[key(c)] = c
                end
            end
            return
        end
        for vk in VRANGE
            missing = false
            for raw_flow in bus.raw_flows
                if !haskey(raw_flow, vk) 
                    missing = true
                    break
                end
            end
            if missing continue end
            pairs = shuffle(product(bus.raw_flows[1][vk], bus.raw_flows[2][vk]))
            candidates = Dict()
            for (b1, b2) in pairs
                c = Candidate(vk, length(bus.children))
                add!(c, 1, collect(b1))
                add!(c, 2, collect(b2))
                candidates[key(c)] = c
            end
            the_rest = [x[vk] for x in bus.raw_flows[3:]]
            for (i,raw_flows) in enumerate(the_rest)
                pairs = shuffle(product(values(candidates), raw_flows))
                candidates = Dict()
                for (candidate, next_bus) in pairs
                    #n += 1
                    new = add(candidate, i+2, collect(next_bus))
                    candidates[key(new)] = new
                end
            end
            merge!(bus.candidates, candidates)
        end
        #bus.raw_flows = [Dict() for child in bus.children]
    end

    buses = Bus[]
    function DFS(bus)
        for child in bus.children DFS(child) end
        push!(buses, bus)
    end
    DFS(root)

    t0 = toq()
    total_time += t0
    for bus in buses[1:end-1]
        assert(bus != root)
        tic()
        f1(bus)
        f2(bus)
        t0 = toq()
	    total_time += t0
        output = @sprintf "%6s %6d %5d %6.2f" bus num_raw_flows(bus) length(bus.candidates) t0
        info(output)
        if verbose print(output, '\n') end
    end

    tic()
    f1root(root)
    f2(root)
    t0 = toq()
    total_time += t0
    output = @sprintf "%6s %6d %5d %6.2f" root num_raw_flows(root) length(root.candidates) t0
    info(output)
    if verbose println(output) end
    output = @sprintf "ALGO FINISHED in %.2f seconds" total_time
    info(output)
    if verbose println(output) end
end;
