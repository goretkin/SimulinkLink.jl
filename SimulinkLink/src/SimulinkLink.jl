module SimulinkLink

using JSON

struct SllObj
    _::Any
end

struct SllNodes{T}
    _::T
end

struct SllNode
    o::Vector{SllObj}
    children::Dict{String, SllNode}
end
SllNode() = SllNode(Vector{SllObj}(), Dict{String, SllNode}())


#deref(handle::Float64) = by_handle[handle]
#get_param(handle::Float64, param::AbstractString) = get_param(deref(handle), param)

function load(json_file)
    j = JSON.Parser.parse(json_file)
    j1 = only(j)

    sl_objects = SllObj.(j1)
    return sl_objects
end

get_param(o::SllObj, param::AbstractString) = o._["get_param"][param]

sl_path_sep = "/"

is_key_unique(pairs) = length(pairs) == length(Set(first(pair) for pair in pairs))

function index(sl_objects)
    handle_pairs = [get_param(o, "Handle") => o for o in sl_objects]

    if !is_key_unique(handle_pairs)
        error("Duplicate Simulink handles")
    end

    by_handle = Dict(handle_pairs)

    function construct_path(o::SllObj)
        p = get_param(o, "Parent")
        q = get_param(o, "Name")
        return "$(p)/$(q)"
    end

    compare_names = [(;gfn = o._["getfullname"], cp = construct_path(o)) for o in sl_objects]
    compare_names = [(;r..., eq = (r.gfn == r.cp)) for r in compare_names]

    # if !(all(cn.eq for cn in compare_names))
    #     print("hmm")
    # end

    name_pairs = [o._["getfullname"] => o for o in sl_objects if !(endswith(o._["getfullname"], sl_path_sep))]

    count_names = Dict()
    for (name, o) in name_pairs
        count_names[name] = 1 + get(count_names, name, 0)
    end

    name_pairs_safe = [k => v for (k, v) in name_pairs if count_names[k] == 1]

    if !is_key_unique(name_pairs_safe)
        # I suspect this can happen with annotations, since Simulink makes the decision to have the "simulink object" name equal the contents of the annotation (very weird).
        error("Duplicate Simulink paths")
    end

    by_name = Dict(name_pairs_safe)
    return (;by_handle, by_name, name_pairs)
end

function make_tree(name_pairs)
    tree = SllNode()

    function add_path!(tree, path_parts, o)
        entry = get!(tree.children, path_parts[1]) do
            SllNode()
        end

        if length(path_parts) == 1
            push!(entry.o, o)
            return
        end

        add_path!(entry, path_parts[2:end], o)
    end

    for (name, o) in name_pairs
        add_path!(tree, split(name, sl_path_sep), o)
    end

    function range_o_length(tree::SllNode)
        n1 = length(tree.o)
        r1 = n1:n1
        r2s = range_o_length.(values(tree.children))
        return reduce(union, [r1, r2s...])
    end

    # for a well-formed tree, it's 1:1
    @show range_o_length(tree)

    return tree
end


include("render.jl")


# https://www.mathworks.com/help/simulink/slref/common-block-parameters.html
# Position: vector of coordinates, in pixels: [left top right bottom]
# The origin is the upper-left corner of the Simulink Editor canvas before any canvas resizing. Supported coordinates are between -1073740824 and 1073740823, inclusive. Positive values are to the right of and down from the origin. Negative values are to the left of and up from the origin.

parse_Position(v) = (;left=v[1], top=v[2], right=v[3], bottom=v[4])

function get_bbox(child_objects)
    _Positions = get_param.(child_objects, "Position")

    geometries = parse_Position.(_Positions)
    geometries = [(;p..., width=p.right-p.left, height=p.bottom-p.top) for p in geometries]

    bbox = (
        mins = (
            minimum(getfield.(geometries, :left)),
            minimum(getfield.(geometries, :top)),
        ),
        maxs = (
            maximum(getfield.(geometries, :right)),
            maximum(getfield.(geometries, :bottom)),
        ),
    )
    return bbox
end

end # module SimulinkLink
