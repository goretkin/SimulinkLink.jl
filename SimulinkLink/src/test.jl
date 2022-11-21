using JSON
f = open("test.json")
j = JSON.Parser.parse(f)
j1 = only(j)


struct SllObj
    _::Any
end

get_param(o::SllObj, param::AbstractString) = o._["get_param"][param]

sl_objects = SllObj.(j1)

handle_pairs = [get_param(o, "Handle") => o for o in sl_objects]


is_key_unique(pairs) = length(pairs) == length(Set(first(pair) for pair in pairs))

if !is_key_unique(handle_pairs)
    error("Duplicate Simulink handles")
end


by_handle = Dict(handle_pairs)

deref(handle::Float64) = by_handle[handle]
get_param(handle::Float64, param::AbstractString) = get_param(deref(handle), param)

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

sl_path_sep = "/"
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

struct SllNode
    o::Vector{SllObj}
    children::Dict{String, SllNode}
end

SllNode() = SllNode(Vector{SllObj}(), Dict{String, SllNode}())

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

simulink_object_types = unique(j1i["get_param"]["Type"] for j1i in j1)
@show simulink_object_types

block_diagrams = [o for o in sl_objects if get_param(o, "Type") == "block_diagram"]

block_diagram = block_diagrams[1]

function table(o::SllObj)
    params = o._["get_param"]
    params_meta = o._["ObjectParameters"]
    k1 = keys(params)
    k2 = keys(params_meta) # TODO check
    return [(;param = k , value = params[k], meta = params_meta[k]) for k in sort(collect(k1))]
end

# check is specific to ACC model
n1 = get_param(block_diagram, "Blocks") |> length
n2 = tree.children["ACC"].children |> length
@show n1 n2  # n2 = n1 + 1

nodes = collect(values(tree.children["ACC"].children))
child_objects = [only(n.o) for n in nodes if length(n.o) == 1]
_Positions = get_param.(child_objects, "Position")

# https://www.mathworks.com/help/simulink/slref/common-block-parameters.html
# Position: vector of coordinates, in pixels: [left top right bottom]
# The origin is the upper-left corner of the Simulink Editor canvas before any canvas resizing. Supported coordinates are between -1073740824 and 1073740823, inclusive. Positive values are to the right of and down from the origin. Negative values are to the left of and up from the origin.

parse_Position(v) = (;left=v[1], top=v[2], right=v[3], bottom=v[4])

geometries = parse_Position.(_Positions)
geometries = [(;p..., width=p.right-p.left, height=p.bottom-p.top) for p in geometries]

bbox = (
    (
        minimum(getfield.(geometries, :left)),
        minimum(getfield.(geometries, :top)),
    ),
    (
        maximum(getfield.(geometries, :right)),
        maximum(getfield.(geometries, :bottom)),
    ),
)

using Gadfly, DataFrames

D = DataFrame(
    x1 = getfield.(geometries, :left),
    y1 = getfield.(geometries, :top),
    x2 = getfield.(geometries, :right),
    y2 = getfield.(geometries, :bottom),
)

p1 = plot(D, xmin=:x1, ymin=:y1, xmax=:x2, ymax=:y2, color=[colorant"green"],
    alpha=fill(0.7, DataFrames.nrow(D)), Geom.rect)

# using Compose


# bbox_wh = (bbox[1], bbox[2] .- bbox[1])
# bbox_wh4 = (bbox_wh[1]..., bbox_wh[2]...)

# #c0 = UnitBox(bbox_wh4...);
# c0 = context(bbox_wh4...)

# # c = compose(c0,
# #     [(context(), rect, fill("tomato")) for rect in _Position.(_Positions)]...
# # )

# ps = parse_Position.(_Positions)
# ps2 = [(;p..., width=p.right-p.left, height=p.bottom-p.top) for p in ps]

# rectangles = rectangle(
#     getfield.(ps2, :left),
#     getfield.(ps2, :top),
#     getfield.(ps2, :width),
#     getfield.(ps2, :height),
# )

# c = compose(c0,
#     (context(), rectangles, fill("blue"))
#  )


# c |> SVG("test.svg")