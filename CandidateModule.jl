module CandidateModule

type Candidate
    n::Int64; p::Float64; v::Float64; children::Array{Float64,2}
end
function Candidate(v, n::Int64)
    p = 0.
    children = -1*ones(3, n)
    Candidate(n, p, v, children)
end
function Candidate(v, children::Array{Float64,2})
    p = sum(children[1,:])
    n = size(children,2)
    Candidate(n, p, v, children)
end

import Base.isless
isless(x::Candidate, y::Candidate) = x.p < y.p

function add!(cand::Candidate, i, child)
    cand.p = cand.p + child[1]
    cand.children[:,i] = child
end
function add(cand::Candidate, i, child)
    result = Candidate(cand.v, copy(cand.children))
    result.p = cand.p + child[1]
    result.children[:,i] = child
    result
end

export Candidate, add, add!, isless

end # CandidateModule
