@kwdef struct ArgumentParser
    prog::Optional{String} = nothing
    usage::Optional{String} = nothing
    description::Optional{String} = nothing
    epilog::Optional{String} = nothing
    add_help::Bool = true
    positional_args::Vector{Argument} = Argument[]
    optional_args::Vector{Argument} = Argument[]
    _flag_args::LittleDict{String,Argument} = LittleDict{String,Argument}()
end

function argument_adder(parser::ArgumentParser)
    function add_argument(name_or_flags::String...; kwargs...)
        ArgParse2.add_argument(parser, name_or_flags...; kwargs...)
    end
end

function add_argument(parser::ArgumentParser, name_or_flags::String...; kwargs...)
    arg = Argument(name_or_flags...; kwargs...)

    if is_positional(arg)
        push!(parser.positional_args, arg)
    else
        for flag in arg.flags
            flag in keys(parser._flag_args) && throw(ArgumentError("flag `$flag` defined multiple times"))
            parser._flag_args[flag] = arg
        end
        push!(parser.optional_args, arg)
    end

    nothing
end

is_positional(arg::Argument) = isempty(arg.flags)

