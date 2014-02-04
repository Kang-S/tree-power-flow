using BusModule

function parse_matpower(casefile)
    # assumes the buses are numbered in order from 1 to n and 1 is the root
    # can relax later if needed
    lines = open(readlines, casefile)
    i = 1
    while ~ismatch(r"mpc.bus = \[", lines[i]) i += 1 end
    i += 1
    demands = Float64[]
    while ~ismatch(r"\];", lines[i])
        m = match(r"(\d+)\s+\d\s+([\d\.]+)", lines[i])
        bus, d = m.captures
        bus = parseint(bus) # unused, might want it later though
        d = parsefloat(d)
        push!(demands, d)
        i += 1
    end
    i += 1
    while ~ismatch(r"mpc.branch = \[", lines[i]) i += 1 end
    i += 1
    admittances = {1=>()}
    children = [i=>Int[] for i=1:length(demands)]
    while ~ismatch(r"\];", lines[i])
        m = match(r"(\d+)\s+(\d+)\s+([\d\.]+)\s+([\d\.]+)", lines[i])
        fbus, tbus, r, x = m.captures
        fbus, tbus = parseint(fbus), parseint(tbus)
        if fbus > tbus
            fbus, tbus = tbus, fbus
        end
        r, x = parsefloat(r), parsefloat(x)
        g, b = r/(r^2+x^2), -x/(r^2+x^2)
        admittances[tbus] = (fbus,g,b)
        push!(children[fbus], tbus)
        i += 1
    end
    demands, admittances, children
end

function assemble_buses(demands, admittances, children)
    # assumes children are always numbered higher than parents
    buses = Array(Bus, length(demands))
    for i=length(demands):-1:2
        d = demands[i]
        name = "$i"
        g, b = admittances[i][2], admittances[i][3]
        c = [buses[j] for j in children[i]]
        buses[i] = Bus(d=d, name=name, children=c, g=g, b=b)
    end
    d = demands[1]
    c = [buses[j] for j in children[1]]
    buses[1] = Bus(d=d, name="1", children=c)
    buses
end

function loadcase(casefile)
    d,a,c = parse_matpower(casefile)
    assemble_buses(d,a,c)
end;
