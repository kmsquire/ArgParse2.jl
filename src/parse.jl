function parse_args(parser::ArgumentParser, args = ARGS)
    args = simplify_args(args)

    pos_arg_state = iterate(parser.positional_args)
    cmdline_arg_state = iterate(args)

    arg_vars = init_arg_variables(parser)
    unseen_req_args = get_required_args(parser)

    while cmdline_arg_state !== nothing
        cmdline_arg = cmdline_arg_state[1]
        if is_flag(cmdline_arg, parser.has_numeric_flags[])
            cmdline_arg_state = parse_optional_arg(parser, args, arg_vars, unseen_req_args, cmdline_arg_state)
        else
            pos_arg_state, cmdline_arg_state = parse_positional_arg(parser, args, arg_vars, unseen_req_args, pos_arg_state, cmdline_arg_state)
        end
    end

    if !isempty(unseen_req_args)
        throw(ArgumentError("the following arguments are required: $(join(unseen_req_args, ", "))"))
    end

    return collect_arg_values(arg_vars)
end

function simplify_args(args)
    new_args = String[]
    for arg in args
        dash_count, remainder = remove_dashes(arg)
        if dash_count === 1 && length(remainder) > 1
            for c in remainder
                push!(new_args, "-$c")
            end
        elseif dash_count == 2 && occursin('=', arg)
            split_args = split(arg, '=', limit = 2)
            push!(new_args, split_args...)
        else
            push!(new_args, arg)
        end
    end

    return new_args
end

function init_arg_variables(parser::ArgumentParser)
    arg_vars = LittleDict{Symbol,Variable}()

    for arg in parser.positional_args
        name = arg.dest
        current_arg_var = get(arg_vars, name, nothing)
        arg_vars[name] = init_arg_variable(arg, current_arg_var)
    end

    for arg in parser.optional_args
        arg.action === :help && continue
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
    unseen_req_args = String[]
    for arg in parser.positional_args
        arg.required && push!(unseen_req_args, arg.name)
    end

    for arg in parser.optional_args
        arg.required && push!(unseen_req_args, arg.default_flag)
    end

    return unseen_req_args
end

is_flag(arg::AbstractString, parser_has_numeric_flags::Bool) =
    startswith(arg, '-') && (!is_numeric(arg) || parser_has_numeric_flags)

function parse_positional_arg(parser, args, arg_vars, unseen_req_args, pos_arg_state, cmdline_arg_state)
    pos_arg_state === nothing && throw(ArgumentError("Found a positional argument, but no place to put it!"))

    argument, positional_state = pos_arg_state
    cmdline_value, cmdline_state = cmdline_arg_state

    var = arg_vars[argument.dest]

    parse_cmdline_arg(cmdline_value, var, argument.choices, argument.name)

    if argument.required
        idx = findfirst(==(argument.name), unseen_req_args)
        idx !== nothing && deleteat!(unseen_req_args, idx)
    end

    pos_arg_state = iterate_positional_args(argument.nargs, var, parser.positional_args, argument, positional_state)
    cmdline_arg_state = iterate(args, cmdline_state)

    return pos_arg_state, cmdline_arg_state
end

function iterate_positional_args(nargs::Integer, var::Variable{T,Vector{T}}, positional_args, argument, positional_state) where T
    length(var.value) < nargs && return (argument, positional_state)
    return iterate(positional_args, positional_state)
end

function iterate_positional_args(nargs::Integer, var, positional_args, argument, positional_state)
    nargs > 1 && throw(ArgumentError("Unexpected nargs value ('$nargs') when parsing $(argument.name)"))
    return iterate(positional_args, positional_state)
end

function iterate_positional_args(nargs::Symbol, var::Variable{T,Vector{T}}, positional_args, argument, positional_state) where T
    !(nargs in [:+, :*]) && throw(ArgumentError("Unexpected nargs value ('$nargs') when parsing $(argument.name)"))
    return (argument, positional_state)
end

function iterate_positional_args(nargs::Symbol, var, positional_args, argument, positional_state)
    nargs in [:+, :*] && throw(ArgumentError("Unexpected nargs value ('$nargs') when parsing $(argument.name)"))
    return iterate(positional_args, positional_state)
end

parse_item(::Type{T}, str::AbstractString, name) where T = parse(T, str)
parse_item(::Type{Optional{T}}, str::AbstractString, name) where T = parse(T, str)
parse_item(::Type{<:AbstractString}, str::AbstractString, name) = str

function parse_item(::Type{<:AbstractChar}, str::AbstractString, name)
    if length(str) !== 1
        throw(ArgumentError("Argument for $(name) must be a single character"))
    end
    return str[1]
end

function parse_cmdline_arg(cmdline_arg::AbstractString, var::Variable{T}, choices, name) where T
    value = parse_item(T, cmdline_arg, name)
    if choices !== nothing
        if !(value in choices)
            throw(ArgumentError("$name must be one of $choices"))
        end
    end
    set_value(var, value)
    nothing
end

function parse_optional_arg(parser, args, arg_vars, unseen_req_args, cmdline_arg_state)
    cmdline_flag, cmdline_state = cmdline_arg_state
    argument = parser.flag_args[cmdline_flag]

    if argument.action == :help
        show_help(parser)
    end

    dest_variable = arg_vars[argument.dest]
    nargs = argument.nargs

    if nargs === 0
        cmdline_arg_state = process_zero_arg_flag(argument,
            argument.action,
            dest_variable,
            args,
            cmdline_flag,
            cmdline_state)
    else
        cmdline_arg_state = process_flag(nargs,
            dest_variable,
            args,
            argument.choices,
            cmdline_flag,
            cmdline_state,
            parser.has_numeric_flags[])
    end

    if argument.required
        idx = findfirst(==(argument.default_flag), unseen_req_args)
        idx !== nothing && deleteat!(unseen_req_args, idx)
    end

    return cmdline_arg_state
end

function process_zero_arg_flag(argument, action, dest_variable, args, cmdline_flag, cmdline_state)
    if action === :store_true
        set_value(dest_variable, true)
    elseif action === :store_false
        set_value(dest_variable, false)
    elseif action === :store_const
        set_value(dest_variable, argument.constant)
    elseif action === :append_const
        set_value(dest_variable, argument.constant)
    elseif action === :count
        set_value(dest_variable, get_value(dest_variable) + 1)
    else
        throw(ArgumentError("Unexpected action '$action' for $cmdline_flag"))
    end

    return iterate(args, cmdline_state)
end

function process_flag(nargs, dest_variable, args, choices, cmdline_flag, cmdline_state, parser_has_numeric_flags)
    arg_count = 0

    flag_state = iterate(args, cmdline_state)
    while flag_state !== nothing
        flag_value, cmdline_state = flag_state
        is_flag(flag_value, parser_has_numeric_flags) && break

        parse_cmdline_arg(flag_value, dest_variable, choices, cmdline_flag)
        arg_count += 1

        flag_state = iterate(args, cmdline_state)
        no_more_args(nargs, arg_count) && break
    end

    if insufficient_args(nargs, arg_count)
        throw(ArgumentError("Insufficient arguments for $cmdline_flag"))
    end

    return flag_state
end

no_more_args(nargs::Integer, arg_count) = arg_count == nargs
no_more_args(nargs::Symbol, arg_count) = nargs === :? && arg_count == 1

insufficient_args(nargs::Integer, arg_count::Integer) = arg_count < nargs
insufficient_args(nargs::Symbol, arg_count::Integer) = nargs === :+ && arg_count == 0

function collect_arg_values(parsed_vars::AbstractDict)
    values = LittleDict{Symbol,Any}()
    for (key, var) in parsed_vars
        values[key] = get_value(var)
    end
    return (;values...)
end

