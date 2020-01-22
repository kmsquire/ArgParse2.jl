module ArgParse2

using Base: @kwdef
using IterTools: imap
using InvertedIndices: Not
using OrderedCollections: LittleDict

export ArgumentParser, Argument, add_argument

const Optional{T} = Union{T,Nothing}

include("argument.jl")
include("target.jl")
include("argument_parser.jl")

end # module
