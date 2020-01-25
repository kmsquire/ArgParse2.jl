module ArgParse2

using Base: @kwdef
using OrderedCollections: LittleDict, OrderedSet

export ArgumentParser, add_argument, argument_adder, parse_args

const Optional{T} = Union{T,Nothing}

include("utils.jl")
include("argument.jl")
include("variable.jl")
include("argument_parser.jl")

end # module
