module SimulinkLink

struct SllObj
    _::Any
end

struct SllNodes{T}
    _::T
end

include("render.jl")


end # module SimulinkLink
