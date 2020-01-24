module ArgParse2

using Base: @kwdef
using OrderedCollections: LittleDict

export ArgumentParser, add_argument, argument_adder, parse_args, show_help, show_usage

const Optional{T} = Union{T,Nothing}

include("utils.jl")
include("argument.jl")
include("variable.jl")
include("argument_parser.jl")
include("help.jl")
include("parse.jl")

end # module
