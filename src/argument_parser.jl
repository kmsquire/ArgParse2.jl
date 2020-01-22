@kwdef struct ArgumentParser
    prog::Optional{String} = nothing
    usage::Optional{String} = nothing
    description::Optional{String} = nothing
    epilog::Optional{String} = nothing
    add_help::Bool = true
    positional_args::Vector{Argument} = Argument[]
    optional_args::Vector{Argument} = Argument[]
    flag_targets::LittleDict{String,Tuple{Argument,Any}} = LittleDict{String,Tuple{Argument,Any}}()
    targets::LittleDict{Symbol,Any} = LittleDict{Symbol,Any}()
end

function argument_adder(parser::ArgumentParser)
    function add_argument(arg::Argument)
        if is_positional(arg)
            push!(parser.positional_args, arg)
            push!(parser.positional_state, empty_arg_state(arg))
            return
        end

        # Argument is optional
        push!(parser.optional_args, arg)
        for flag in arg.flags
            parser.flags2args[flag] = arg
        end
    end
end

function add_argument(parser::ArgumentParser, args::Argument...)
    argument_adder(parser).(args)
    nothing
end

is_positional(arg::Argument) = isempty(arg.flags)

function parse(parser::ArgumentParser, args::Vector{String} = ARGS)

end
