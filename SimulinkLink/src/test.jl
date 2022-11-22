using SimulinkLink
import SimulinkLink: SllNodes, SllObj, get_param


sl_objects = SimulinkLink.load(open("test.json"))
(;by_handle, by_name, name_pairs) = SimulinkLink.index(sl_objects)
tree = SimulinkLink.make_tree(name_pairs)

simulink_object_types = unique(get_param(o, "Type") for o in sl_objects)
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



using Gadfly, DataFrames

geometries = SimulinkLink.parse_Position.(get_param.(child_objects, "Position"))

D = DataFrame(
    x1 = getfield.(geometries, :left),
    y1 = getfield.(geometries, :top),
    x2 = getfield.(geometries, :right),
    y2 = getfield.(geometries, :bottom),
)

p1 = plot(D, xmin=:x1, ymin=:y1, xmax=:x2, ymax=:y2, color=[colorant"green"],
    alpha=fill(0.7, DataFrames.nrow(D)), Geom.rect)
