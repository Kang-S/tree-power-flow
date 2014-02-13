using BusModule

function parse_matpower(casefile)
    lines = open(readlines, casefile)
    i = 1
    while ~ismatch(r"mpc.bus = \[", lines[i]) i += 1 end
    i += 1
    demands = Dict()
    root = 1
    while ~ismatch(r"\];", lines[i])
        bus, bus_type, d = split(lines[i])
        bus, bus_type, d = parseint(bus), parseint(bus_type), parsefloat(d)
        if bus_type == 3 root = bus end
        demands[bus] = d
        i += 1
    end
    i += 1
    while ~ismatch(r"mpc.branch = \[", lines[i]) i += 1 end
    i += 1
    #admittances = {root=>(NaN, NaN)}
    admittances = [i=>Dict() for i in keys(demands)]
    children = [i=>Int[] for i in keys(demands)]
    while ~ismatch(r"\];", lines[i])
        fbus, tbus, r, x = split(lines[i])
        fbus, tbus, r, x = parseint(fbus), parseint(tbus), parsefloat(r), parsefloat(x)
        g, b = r/(r^2+x^2), -x/(r^2+x^2)
        admittances[fbus][tbus] = (g,b)
        admittances[tbus][fbus] = (g,b)
        #admittances[tbus] = (g,b)
        #push!(children[fbus], tbus)
        i += 1
    end
    #demands, admittances, children, root
    admittances[root][-1] = (NaN, NaN)
    demands, admittances, root
end

function assemble_buses(demands, admittances, root)
    # currently a bus's children need to be defined before it can be constructed,
    # so post-order depth-first search the tree
    buses = Dict()
    function construct_bus(i, parent)
        d = demands[i]
        name = "$i"
        #c = [buses[j] for j in children[i]]
        c = Bus[]
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

function assemble_buses(demands, admittances, children, root)
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
    DFS(root)
    buses[root]
end

function loadcase(casefile)
    d,a,r = parse_matpower(casefile)
    assemble_buses(d,a,r)
    #d,a,c,r = parse_matpower(casefile)
    #assemble_buses(d,a,c,r)
end;
