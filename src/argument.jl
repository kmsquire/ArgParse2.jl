const VECTOR_TYPE = true
const SCALAR_TYPE = false

struct Argument{T,U,V}
    name::String
    flags::Vector{String}
    nargs::Union{Int,Symbol}
    default_flag::Optional{String}
    action::Optional{Symbol}
    constant::Optional{T}
    default::U
    choices::Optional{AbstractVector{T}}
    required::Bool
    help::Optional{String}
    metavar::Optional{String}
    dest::Symbol
end

function Argument(name_or_flags::Union{Symbol,String}...;
    type::DataType = Nothing,
    nargs::Union{Int,Char,String,Nothing} = nothing,
    action::Union{Symbol,String,Nothing} = nothing,
    constant::R = nothing,
    default::Union{Vector{S},S} = nothing,
    choices::Union{AbstractVector{T},T} = nothing,
    required::Bool = false,
    help::Optional{String} = nothing,
    metavar::Optional{String} = nothing,
    dest::Union{Symbol,String,Nothing} = nothing) where {R,S,T}

    name, default_flag, flags = parse_name_flags(name_or_flags)
    if dest === nothing
        dest = Symbol(name)
    end

    action = to_symbol(action)
    dest = to_symbol(dest)
    nargs = to_symbol(nargs)

    validate_action(action)

    if type === Nothing
        if action in [:store_true, :store_false]
            type = Bool
        elseif action === :count
            type = Int
        else
            type = coalesce_promote_types(R, S, T)
        end
    end

    if default === nothing
        if action in [:store_true, :store_false]
            default = action === :store_true ? false : true
        elseif action === :count
            default = 0
        end
    end

    nargs = get_nargs(nargs, type, action)
    validate_nargs(nargs)

    if isempty(flags)
        # This is a positional argument, so check if it is required
        required = nargs !== :? && nargs !== :*
    end

    dest_is_vector = need_vector(action, nargs, default)

    validate_args(action, nargs, constant, default, type, choices, dest_is_vector)

    Argument{type,typeof(default),dest_is_vector}(
        name,
        flags,
        nargs,
        default_flag,
        action,
        constant,
        default,
        choices,
        required,
        help,
        metavar,
        dest)
end


to_symbol(::Nothing) = nothing
to_symbol(n::Number) = n
to_symbol(s) = Symbol(s)

function need_vector(action, nargs, default)
    return action in [:append, :append_const] || multiple_values(nargs) || default isa AbstractVector
end

multiple_values(nargs::Integer) = nargs > 1
multiple_values(nargs::Symbol) = nargs in [:+, :*]

function parse_name_flags(name_or_flags::Tuple{Vararg{Union{Symbol,String}}})
    if length(name_or_flags) === 1 && Base.isidentifier(name_or_flags[1])
        name = String(name_or_flags[1])
        return name, nothing, String[]
    end

    flag_names, flags = extract_flag_names(name_or_flags)
    default_flag = flags[1]
    name = longest(flag_names)

    return name, default_flag, flags
end

function extract_flag_names(input_flags)
    flags = String[]
    flag_names = String[]

    for flag in input_flags
        if !(flag isa AbstractString)
            throw(ArgumentError("Invalid flag: `$flag`"))
        end

        dash_count, rest = remove_dashes(flag)

        if !(1 <= dash_count <= 2) || length(rest) === 0
            throw(ArgumentError("Invalid flag: `$flag`"))
        end

        push!(flag_names, replace(rest, '-' => '_'))
        push!(flags, flag)
    end

    return flag_names, flags
end

function coalesce_promote_types(types::DataType...)
    length(types) === 0 && return String

    ret_type = Nothing

    for type in types
        if type !== Nothing
            ret_type = ret_type === Nothing ? type : promote_type(ret_type, type)
        end
    end

    ret_type === Nothing && return String

    return ret_type
end

function validate_args(action, nargs, constant, default, type, choices, dest_is_vector)
    @nospecialize

    if action in [:store_true, :store_false, :store_const, :append_const, :count]
        # Test that nargs and action are consistent
        if nargs !== nothing && nargs !== 0
            throw(ArgumentError("nargs=`$nargs` cannot be specified with action=`$action`"))
        end

        # Test that action and choices are consistent
        if choices !== nothing
            throw(ArgumentError("You cannot specify `choices` for action=`$action`"))
        end
    end

    # Test that nargs and constant are consistent
    if action in [:store_const, :append_const] && constant === nothing
        throw(ArgumentError("Please provide a value for `constant` to use with $action"))
    end

    # Test that default is a vector if necessary
    if default !== nothing && dest_is_vector && !(default isa AbstractVector)
        throw(ArgumentError("Default value must be a vector"))
    end

    # Test that default and choices are consistent
    if choices !== nothing && default !== nothing
        if dest_is_vector
            # We made sure that default was a vector above
            for value in default
                test_value_in_choices(value, choices)
            end
        else
            test_value_in_choices(default, choices)
        end
    end


end

function test_value_in_choices(value, choices)
    if !(value in choices)
        throw(ArgumentError("Default value `$value` must be one of $choices"))
    end
end

validate_action(action) = nothing
function validate_action(action::Symbol)
    if !(action in [:store_true, :store_false, :store_const, :append, :append_const, :count, :help])
        throw(ArgumentError("Invalid action: `$(String(action))`"))
    end
end

validate_nargs(nargs) = nothing
function validate_nargs(nargs::Symbol)
    if !(nargs in [:?, :+, :*])
        throw(ArgumentError("Invalid specifier `$nargs` for `nargs`"))
    end
end

get_nargs(nargs::Nothing, ::Type{Bool}, action) = 0
get_nargs(nargs::Nothing, ::Type{<:Vector}, action) = :*
get_nargs(nargs::Nothing, _, action) = action in [:store_true, :store_false, :store_const, :append_const, :count, :help] ? 0 : 1
get_nargs(nargs::Union{Int,Symbol}, _, _) = nargs

function arg_name(arg::Argument, to_uppercase = true)
    name = to_uppercase ? uppercase(arg.name) : arg.name
    return something(arg.metavar, name)
end
