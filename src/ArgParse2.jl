module ArgParse2

using OrderedCollections: LittleDict
using TextWrap: println_wrapped, wrap

export ArgumentParser, add_argument!, argument_adder, parse_args, show_help, show_usage
export add_argument  # TODO: Remove add_argument before registering

const Optional{T} = Union{T,Nothing}

include("utils.jl")
include("argument.jl")
include("variable.jl")
include("argument_parser.jl")
include("help.jl")
include("parse.jl")

include("precompile.jl")

_precompile_()

end # module
