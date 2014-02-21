using BusModule

function parse_matpower(casefile)
    lines = open(readlines, casefile)
    i = 1
    while ~ismatch(r"mpc.bus = \[", lines[i]) i += 1 end
    i += 1
    demands = Dict()
    root, vhat = 1, 1.0
    while ~ismatch(r"\];", lines[i])
        bus, bus_type, d = split(lines[i])
        bus, bus_type, d = parseint(bus), parseint(bus_type), parsefloat(d)
        if bus_type == 3 root = bus end
        demands[bus] = d
        i += 1
    end
    while ~ismatch(r"mpc.gen = \[", lines[i]) i += 1 end
    i += 1
    while ~ismatch(r"\];", lines[i])
        bus, p, _, _, _, v = split(lines[i])
        bus, p, v = parseint(bus), parsefloat(p), parsefloat(v)
        if bus == root
            vhat = v
        else
            demands[bus] -= p
        end
        i += 1
    end
    while ~ismatch(r"mpc.branch = \[", lines[i]) i += 1 end
    i += 1
    admittances = [i=>Dict() for i in keys(demands)]
    admittances[root][-1] = (NaN, NaN)
    children = [i=>Int[] for i in keys(demands)]
    while ~ismatch(r"\];", lines[i])
        fbus, tbus, r, x = split(lines[i])
        fbus, tbus, r, x = parseint(fbus), parseint(tbus), parsefloat(r), parsefloat(x)
        g, b = r/(r^2+x^2), -x/(r^2+x^2)
        admittances[fbus][tbus] = (g,b)
        admittances[tbus][fbus] = (g,b)
        i += 1
    end
    demands, admittances, root, vhat
end

function assemble_buses(demands, admittances, root)
    # currently a bus's children need to be defined before it can be constructed,
    # so post-order depth-first search the tree
    buses = Dict()
    function construct_bus(i, parent)
        d = demands[i]
        name = "$i"
        c = Bus[] # ugh, this is a one-liner in Python
        for child in keys(admittances[i])
            if child != parent 
                push!(c, buses[child])
            end
        end
        g, b = admittances[i][parent]
        buses[i] = Bus(d=d, name=name, children=c, g=g, b=b)
    end
    function DFS(i, parent) 
        for child in keys(admittances[i]) 
            if child != parent DFS(child, i) end
        end
        construct_bus(i, parent)
    end
    DFS(root, -1)
    buses[root]
end

function loadcase(casefile)
    d,a,r,vhat = parse_matpower(casefile)
    root = assemble_buses(d,a,r)
    root, vhat
end;

