using BusModule

function parse_matpower(casefile)
    # assumes 1 is the root; can change that to first slack bus (type 3) if necessary
    lines = open(readlines, casefile)
    i = 1
    while ~ismatch(r"mpc.bus = \[", lines[i]) i += 1 end
    i += 1
    demands = Dict()
    while ~ismatch(r"\];", lines[i])
        m = match(r"(\d+)\s+\d\s+([\d\.]+)", lines[i])
        bus, d = m.captures
        bus, d = parseint(bus), parsefloat(d)
        demands[bus] = d
        i += 1
    end
    i += 1
    while ~ismatch(r"mpc.branch = \[", lines[i]) i += 1 end
    i += 1
    admittances = {1=>(NaN, NaN)}
    children = [i=>Int[] for i in keys(demands)]
    while ~ismatch(r"\];", lines[i])
        m = match(r"(\d+)\s+(\d+)\s+([\d\.]+)\s+([\d\.]+)", lines[i])
        fbus, tbus, r, x = m.captures
        fbus, tbus = parseint(fbus), parseint(tbus)
        if fbus > tbus
            fbus, tbus = tbus, fbus
        end
        r, x = parsefloat(r), parsefloat(x)
        g, b = r/(r^2+x^2), -x/(r^2+x^2)
        admittances[tbus] = (g,b)
        push!(children[fbus], tbus)
        i += 1
    end
    demands, admittances, children
end

function assemble_buses(demands, admittances, children)
    # currently a bus's children need to be defined before it can be constructed,
    # so post-order depth-first search the tree
    buses = Dict()
    function construct_bus(i)
        d = demands[i]
        name = "$i"
        c = [buses[j] for j in children[i]]
        g, b = admittances[i]
        buses[i] = Bus(d=d, name=name, children=c, g=g, b=b)
    end
    function DFS(i)
        for child in children[i] DFS(child) end
        construct_bus(i)
    end
    DFS(1)
    buses[1]
end

function loadcase(casefile)
    d,a,c = parse_matpower(casefile)
    assemble_buses(d,a,c)
end;
