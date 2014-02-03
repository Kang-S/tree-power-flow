module BusModule

type Bus
    d::Float64; name; children; g::Float64; b::Float64; raw_flows; candidates
    function Bus(;d=0., name="0", children=[], g=1., b=-10.)
        raw_flows = [Dict() for child in children]
        new(d, name, children, g, b, raw_flows, Dict())
    end
end
import Base.print
function print(io::IO, b::Bus)
    name = b.name
    print(io, "bus$name")
end;
import Base.show
show(io::IO, b::Bus) = print(io, b, " show")
export Bus, print, show

end # module BusModule
