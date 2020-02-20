HELP_TEXT = "show this help message and exit"

struct ArgumentParser
    prog::Optional{String}
    usage::Optional{String}
    description::Optional{String}
    epilog::Optional{String}
    positional_args::Vector{Argument}
    optional_args::Vector{Argument}
    flag_args::LittleDict{String,Argument}
    has_numeric_flags::Ref{Bool}
end

function ArgumentParser(;
    prog = nothing,
    usage = nothing,
    description = nothing,
    epilog = nothing,
    add_help = true)

    positional_args = Argument[]
    optional_args = Argument[]
    flag_args = LittleDict{String,Argument}()
    has_numeric_flags = Ref{Bool}(false)

    parser = ArgumentParser(prog, usage, description, epilog, positional_args, optional_args, flag_args, has_numeric_flags)
    add_help && add_argument!(parser, "-h", "--help", action = "help", help = HELP_TEXT)

    return parser
end

function argument_adder(parser::ArgumentParser)
    function add_argument!(name_or_flags::String...; kwargs...)
        ArgParse2.add_argument!(parser, name_or_flags...; kwargs...)
    end
end

function add_argument(args...; kwargs...)
    @warn """add_argument(...) is deprecated and will be removed before ArgParse2 is registered.
             Please use add_argument!(...)""" maxlog=1
end

function add_argument!(parser::ArgumentParser, name_or_flags::String...; kwargs...)
    arg = Argument(name_or_flags...; kwargs...)

    if is_positional(arg)
        push!(parser.positional_args, arg)
    else
        for flag in arg.flags
            flag in keys(parser.flag_args) && throw(ArgumentError("flag `$flag` defined multiple times"))
            parser.flag_args[flag] = arg
            if is_numeric(flag)
                parser.has_numeric_flags[] = true
            end
        end
        push!(parser.optional_args, arg)
    end

    nothing
end

is_positional(arg::Argument) = isempty(arg.flags)

