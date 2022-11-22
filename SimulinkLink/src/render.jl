using Colors, UUIDs
include("svgwriter.jl")

Base.showable(::MIME"image/svg+xml", ::SllObjs) = true

# If html embedding does not work, redefine the following method to return `false`.
Base.showable(::MIME"text/html", ::SllObjs) = true

function Base.show(io::IO, mime::Union{MIME"image/svg+xml", MIME"text/html"}, objs::SllObjs)
    if mime isa MIME"text/html"
        print(io, """
            <!DOCTYPE html>
            <html>
            <body>
            """)
    else
        write_svgdeclaration(io)
    end

    show_body(io, objs)

    if mime isa MIME"text/html"
        print(io, """
            </body>
            </html>
            """)
    end
end

function show_body(io::IO, objs::SllObjs)
    fg = (;
        fontsize = 12,
        roundradius = 2,
        bgcolor=:fcolor,
        fontcolor=:fcolor,
        frameopacity=1,
        font="inherit",
        notext=false,
        timeunit=:none,
        delay=0.0,
    )

    (;mins, maxs) = get_bbox(objs._)
    dims = maxs .- mins
    width = dims[1]
    leftmargin = rightmargin = round(Int, width * 0.01)
    topmargin = botmargin = round(Int, max(width * 0.04, fg.fontsize * 3))

    height = dims[2]

    xstep = 1.0 # ??? used in viewer.js

    fig_id = string("fig-", replace(string(uuid4()), "-" => ""))

    write_svgheader(io, fig_id, width, height,
                    bgcolor(fg), fontcolor(fg), fg.frameopacity,
                    fg.font, fg.fontsize, fg.notext, xstep, fg.timeunit, fg.delay)


    for obj in objs._
        (;p1, p2) = parse_Position2(get_param(obj, "Position"))
        dim = p2 .- p1

        (x, y) = p1
        (w, h) = dim

        yt = simplify(y + height * 0.75)

        shortinfo = obj._["getfullname"]
        dirinfo = "dirblah"
        color = colorant"green"
        r = fg.roundradius
        bw = fg.fontcolor === :bw

        sinfo = escape_html(shortinfo)
        dinfo = escape_html(dirinfo)
        classw = (bw & isdarkcolor(color)) ? " class=\"w\"" : ""
        if r > zero(r)
            print(io, """<rect x="$x" y="$y" width="$w" height="$h" rx="$r" """)
        else
            print(io, """<path d="M$x,$(y)v$(h)h$(w)v-$(h)z" """)
        end
        println(io, """fill="#$(hex(color))" data-dinfo="$dinfo"/>""")
        println(io, """<text x="$x" dx="4" y="$yt"$classw>$sinfo</text>""")
    end

    write_svgfooter(io, fig_id)
end

function bgcolor(fg)
    fg.bgcolor === :fcolor && return "#" * hex(colorant"white")
    fg.bgcolor === :transparent && return "transparent"
    fg.bgcolor === :classic && return ""
    return "white"
end

function fontcolor(fg)
    fg.fontcolor === :fcolor && return "#" * hex(colorant"black")
    fg.fontcolor === :currentcolor && return "currentcolor"
    fg.fontcolor === :bw && return ""
    return "black"
end


function save_svg(io::IO, g::SllObjs)
    show(io, MIME"image/svg+xml"(), g)
end

function save_svg(filename::AbstractString, g::SllObjs)
    open(filename, "w") do file
        save_svg(file, g)
    end
    return nothing
end