using Colors, UUIDs
include("svgwriter.jl")

Base.showable(::MIME"image/svg+xml", ::SllNodes) = true

# If html embedding does not work, redefine the following method to return `false`.
Base.showable(::MIME"text/html", ::SllNodes) = true

function Base.show(io::IO, mime::Union{MIME"image/svg+xml", MIME"text/html"}, nodes::SllNodes)
    if mime isa MIME"text/html"
        print(io, """
            <!DOCTYPE html>
            <html>
            <body>
            """)
    else
        write_svgdeclaration(io)
    end

    show_body(io, nodes)

    if mime isa MIME"text/html"
        print(io, """
            </body>
            </html>
            """)
    end
end

function show_body(io::IO, nodes::SllNodes)
    ncols, nrows = (1, 1)
    if nrows > fg.maxdepth
        @warn """The depth of this graph is $nrows, exceeding the `maxdepth` (=$(fg.maxdepth)).
                 The deeper frames will be truncated."""
        nrows = fg.maxdepth
    end
    width = fg.width
    leftmargin = rightmargin = round(Int, width * 0.01)
    topmargin = botmargin = round(Int, max(width * 0.04, fg.fontsize * 3))

    idealwidth = width - (leftmargin + rightmargin)
    xstep = Float64(rationalize(idealwidth / ncols, tol = 1 / ncols))
    ystep = round(Int, fg.fontsize * 1.25)

    height = fg.height > 0.0 ? fg.height : ystep * nrows + botmargin * 2.0

    function flamerects(io::IO, g#=::FlameGraph=#, j::Int, nextidx::Vector{Int})
        j > fg.maxdepth && return
        nextidx[end] > fg.maxframes && return
        nextidx[end] += 1

        ndata = g.data
        color = fg.fcolor(nextidx, j, ndata)::Color
        bw = fg.fontcolor === :bw
        x = (first(ndata.span)-1) * xstep + leftmargin
        if fg.yflip
            y = topmargin + (j - 1) * ystep
        else
            y = height - j * ystep - botmargin
        end
        w = length(ndata.span) * xstep
        r = fg.roundradius
        shortinfo, dirinfo = extract_frameinfo(ndata.sf)
        write_svgflamerect(io, x, y, w, ystep, r, shortinfo, dirinfo, color, bw)

        for c in g
            flamerects(io, c, j + 1, nextidx)
        end
    end

    fig_id = string("fig-", replace(string(uuid4()), "-" => ""))

    write_svgheader(io, fig_id, width, height,
                    bgcolor(fg), fontcolor(fg), fg.frameopacity,
                    fg.font, fg.fontsize, fg.notext, xstep, fg.timeunit, fg.delay)

    nextidx = fill(1, nrows + 1) # nextidx[end]: framecount
    flamerects(io, fg.g, 1, nextidx)

    if nextidx[end] > fg.maxframes
        @warn """The maximum number of frames (`maxframes`=$(fg.maxframes)) is reached.
                 Some frames were truncated."""
    end

    write_svgfooter(io, fig_id)
end

function bgcolor(fg)
    fg.bgcolor === :fcolor && return "#" * hex(fg.fcolor(:bg))
    fg.bgcolor === :transparent && return "transparent"
    fg.bgcolor === :classic && return ""
    return "white"
end

function fontcolor(fg)
    fg.fontcolor === :fcolor && return "#" * hex(fg.fcolor(:font))
    fg.fontcolor === :currentcolor && return "currentcolor"
    fg.fontcolor === :bw && return ""
    return "black"
end
