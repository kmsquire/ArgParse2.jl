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
            flag in keys(parser._flag_args) && throw(ArgumentError("Flag `$flag` specified multiple times"))
            parser._flag_args[flag] = arg
        end
        push!(parser.optional_args, arg)
    end

    nothing
end

is_positional(arg::Argument) = isempty(arg.flags)

function parse_args(parser::ArgumentParser, args = ARGS)

    pos_arg_state = iterate(parser.positional_args)
    cmdline_arg_state = iterate(args)

    arg_vars = init_arg_variables(parser)
    required_args = get_required_args(parser)

    while cmdline_arg_state !== nothing
        cmdline_arg = cmdline_arg_state[1]
        if is_flag(cmdline_arg)
            cmdline_arg_state = parse_optional_arg(parser, args, arg_vars, required_args, cmdline_arg_state)
        else
            pos_arg_state, cmdline_arg_state = parse_positional_arg(parser, args, arg_vars, required_args, pos_arg_state, cmdline_arg_state)
        end
    end

    if !isempty(required_args)
        throw(ArgumentError("the following arguments are required: $(join(required_args, ", "))"))
    end

    return collect_arg_values(arg_vars)
end

function init_arg_variables(parser::ArgumentParser)
    arg_vars = LittleDict{Symbol,Variable}()

    for arg in parser.positional_args
        name = arg.dest
        current_arg_var = get(arg_vars, name, nothing)
        arg_vars[name] = init_arg_variable(arg, current_arg_var)
    end

    for arg in parser.optional_args
        name = arg.dest
        current_arg_var = get(arg_vars, name, nothing)
        arg_vars[name] = init_arg_variable(arg, current_arg_var)
    end

    return arg_vars
end

function init_arg_variable(arg, current_arg_var)
    var = empty_var(arg)
    current_arg_var === nothing && return var

    return promote_var(var, current_arg_var)
end

function get_required_args(parser::ArgumentParser)
    required_args = OrderedSet{String}()
    for arg in parser.positional_args
        push!(required_args, arg.name)
    end

    for arg in parser.optional_args
        arg.required && push!(required, arg.flag)
    end

    return required_args
end

is_flag(arg::AbstractString) = startswith(arg, '-')

function parse_positional_arg(parser, args, arg_vars, required_args, pos_arg_state, cmdline_arg_state)
    pos_arg_state === nothing && throw(ArgumentError("Found a positional argument, but no place to put it!"))

    argument, positional_state = pos_arg_state
    cmdline_value, cmdline_state = cmdline_arg_state

    var = arg_vars[argument.dest]

    parse_cmdline_arg(cmdline_value, argument, var)

    if argument.name in required_args
        pop!(required_args, argument.name)
    end

    pos_arg_state = advance(argument.nargs, var, parser.positional_args, argument, positional_state)
    cmdline_arg_state = iterate(args, cmdline_state)

    return pos_arg_state, cmdline_arg_state
end

function advance(nargs::Integer, var::Variable{T, Vector}, positional_args, argument, positional_state) where T
    length(var.value) < nargs && return (argument, positional_state)
    return iterate(positional_args, positional_state)
end

function advance(nargs::Integer, var, positional_args, argument, positional_state)
    nargs > 1 && throw(ArgumentError("Unexpected nargs value ('$nargs') when parsing $(argument.name)"))
    return iterate(positional_args, positional_state)
end

function advance(nargs::Char, var::Variable{T, Vector}, positional_args, argument, positional_state) where T
    nargs in ['+', '*'] && return (argument, positional_state)
    return iterate(positional_args, positional_state)
end

function advance(nargs::Char, var, positional_args, argument, positional_state)
    nargs in ['+', '*'] && throw(ArgumentError("Unexpected nargs value ('$nargs') when parsing $(argument.name)"))
    return iterate(positional_args, positional_state)
end

function parse_cmdline_arg(cmdline_arg::AbstractString, arg::Argument{<:AbstractString,VECTOR_TYPE}, var::Variable)
    push!(var.value, cmdline_arg)
    nothing
end

function parse_cmdline_arg(cmdline_arg::AbstractString, arg::Argument{<:AbstractString,SCALAR_TYPE}, var::Variable)
    var.value = cmdline_arg
    nothing
end

function parse_cmdline_arg(cmdline_arg::AbstractString, arg::Argument{T,VECTOR_TYPE}, var::Variable{T, Vector}) where T
    value = parse(T, cmdline_arg)
    push!(var.value, value)
    nothing
end

function parse_cmdline_arg(cmdline_arg::AbstractString, arg::Argument{T,SCALAR_TYPE}, var::Variable) where T
    var.value = parse(T, cmdline_arg)
    nothing
end

function parse_optional_arg(parser, args, arg_vars, required_args, cmdline_arg_state)
    cmdline_flag, cmdline_state = cmdline_arg_state
    argument = parser._flag_args[cmdline_flag]

    dest_variable = arg_vars[argument.dest]
    nargs = argument.nargs

    if nargs === 0
        cmdline_arg_state = process_zero_arg_flag(argument, dest_variable, args, cmdline_state)
    elseif nargs === 1
        cmdline_arg_state = process_one_arg_flag(argument, dest_variable, args, cmdline_state)
    else
        cmdline_arg_state = process_multi_arg_flag(argument, dest_variable, args, cmdline_state)
    end

    if argument.required && argument.name in required_args
        pop!(required_args, argument.name)
    end

    return cmdline_arg_state
end

function process_zero_arg_flag(argument::Argument{T,VECTOR_TYPE}, dest_variable, args, cmdline_state) where T
    action = argument.action

    if action === :append_const
        push!(dest_variable.value, argument.constant)
    else
        throw(ArgumentError("Unexpected action: $action"))
    end

    return iterate(args, cmdline_state)
end

function process_zero_arg_flag(argument, dest_variable, args, cmdline_state)
    action = argument.action

    if action === :store_true
        dest_variable.value = true
    elseif action === :store_false
        dest_variable.value = false
    elseif action === :store_const
        dest_variable.value = argument.constant
    else
        throw(ArgumentError("Unexpected action: $action"))
    end

    return iterate(args, cmdline_state)
end

function process_one_arg_flag(argument, dest_variable, args, cmdline_state) where T
    flag_value, cmdline_state = iterate(args, cmdline_state)

    parse_cmdline_arg(flag_value, argument, dest_variable)

    return iterate(args, cmdline_state)
end

function process_multi_arg_flag(argument::Argument{T,VECTOR_TYPE}, nargs::Integer, dest_variable, args, cmdline_state) where T
    for i = 1:nargs
        flag_value, cmdline_state = iterate(args, cmdline_state)
        flag_value === nothing && return (flag_value, cmdline_state)
        parse_cmdline_arg(flag_value, argument, dest_variable)
    end

    return iterate(args, cmdline_state)
end

function process_multi_arg_flag(argument::Argument{T,VECTOR_TYPE}, nargs::Char, dest_variable, args, cmdline_state) where T
    !(nargs in ['+','*']) && throw(ArgumentError("Unexpected value for nargs: '$nargs'"))

    arg_count = 0
    flag_value = nothing
    while true
        flag_value, cmdline_state = iterate(args, cmdline_state)
        flag_value === nothing && break
        startswith(flag_value, '-') && break
        parse_cmdline_arg(flag_value, argument, dest_variable)
        arg_count += 1
    end

    if nargs === '+' && arg_count === 0
        throw(ArgumentError("At least one argument expected for flag"))
    end

    return (flag_value, cmdline_state)
end

function process_multi_arg_flag(argument::Argument{T,SCALAR_TYPE}, nargs::Char, dest_variable, args, cmdline_state) where T
    nargs !== '?' && throw(ArgumentError("Unexpected value for nargs: '$nargs'"))

    flag_value, cmdline_state = iterate(args, cmdline_state)
    flag_value === nothing && return (flag_value, cmdline_state)
    startswith(flag_value, '-') && return (flag_value, cmdline_state)
    parse_cmdline_arg(flag_value, argument, dest_variable)

    return iterate(args, cmdline_state)
end

function collect_arg_values(parsed_vars::AbstractDict)
    values = LittleDict{Symbol,Any}()
    for (key, var) in parsed_vars
        values[key] = get_value(var)
    end
    return (;values...)
end

