module BusModule

type Bus
    d::Float64; 
    name; 
    children; 
    g::Float64; 
    b::Float64; 
    raw_flows; 
    candidates;
    pmax
    function Bus(;d=0., name="0", children=[], g=1., b=-10., pmax=Inf)
        raw_flows = [Dict() for child in children]
        new(d, name, children, g, b, raw_flows, Dict(), pmax)
    end
end
function clear!(b::Bus)
    b.raw_flows = [Dict() for child in b.children]
    b.candidates = Dict()
end
function clear!(buses::Array{Bus,1})
	for b in buses clear!(b) end
end
function clear!(buses::Dict{Any,Any})
	for b in values(buses) clear!(b) end
end
function get_buses(root::Bus)
	buses = Bus[]
	function DFS(bus)
	    for child in bus.children DFS(child) end
	    push!(buses, bus)
	end
	DFS(root)
	buses
end
function get_buses_dict(root::Bus)
	buses = get_buses(root)
	buses_dict = {parseint(b.name)=>b for b in buses}
end
import Base.print
function print(io::IO, b::Bus)
    name = b.name
    print(io, "bus$name")
end;
import Base.show
show(io::IO, b::Bus) = print(io, b)
export Bus, clear!, get_buses, get_buses_dict, print, show

end # module BusModule
