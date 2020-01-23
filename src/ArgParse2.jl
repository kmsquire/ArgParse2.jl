module ArgParse2

using Base: @kwdef
using IterTools: imap
using InvertedIndices: Not
using OrderedCollections: LittleDict, OrderedSet

export ArgumentParser, add_argument, argument_adder, parse_args

const Optional{T} = Union{T,Nothing}

include("argument.jl")
include("variable.jl")
include("argument_parser.jl")

end # module
