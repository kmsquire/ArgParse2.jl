using Documenter, ArgParse2

makedocs(;
    modules=[ArgParse2],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/kmsquire/ArgParse2.jl/blob/{commit}{path}#L{line}",
    sitename="ArgParse2.jl",
    authors="Kevin Squire",
    assets=String[],
)

deploydocs(;
    repo="github.com/kmsquire/ArgParse2.jl",
)
