
@kwdef struct Argument{T,V}
    name::String
    flags::Vector{String}
    nargs::Union{Int,Char}
    flag::Optional{String} = nothing
    action::Optional{Symbol} = nothing
    constant::Optional{T} = nothing
    default::Optional{T} = nothing
    choices::Optional{Vector{T}} = nothing
    required::Bool = false
    help::Optional{String} = nothing
    metavar::Optional{String} = nothing
    dest::Symbol
end

const VECTOR_TYPE = true
const SCALAR_TYPE = false

function Argument(name_or_flags::Union{Symbol,String}...;
    action::Union{Symbol,String,Nothing} = nothing,
    nargs::Union{Int,Char,Nothing} = nothing,
    constant::R = nothing,
    default::Union{Vector{S},S} = nothing,
    type::DataType = Nothing,
    choices::Union{Vector{T},T} = nothing,
    dest::Union{Symbol,String,Nothing} = nothing,
    kwargs...) where {R,S,T,U}

    name, flag, flags = parse_name_flags(name_or_flags)
    if dest === nothing
        dest = name
    end

    action = str_to_symbol(action)
    dest = str_to_symbol(dest)

    if default === nothing && action in [:store_true, :store_false]
        default = action === :store_true ? false : true
    end

    if type === Nothing
        if action in [:store_true, :store_false]
            type = Bool
        else
            type = coalesce_promote_types(R, S, T)
        end
    end

    validate_action(action)
    validate_nargs(nargs)

    dest_is_vector = need_vector(action, nargs, default)

    nargs = get_nargs(nargs, type, action)

    validate_args(action, nargs, constant, default, type, choices, dest_is_vector)

    Argument{type, dest_is_vector}(;
        name = name,
        flags = flags,
        nargs = nargs,
        flag = flag,
        action = action,
        constant = constant,
        default = default,
        choices = choices,
        dest = dest,
        kwargs...)
end

str_to_symbol(s::AbstractString) = Symbol(s)
str_to_symbol(s) = s

function need_vector(action, nargs, default)
    return action in [:append, :append_const] || multiple_values(nargs) || default isa AbstractVector
end

multiple_values(nargs::Integer) = nargs > 1
multiple_values(nargs::Char) = nargs in ['+', '*']
multiple_values(nargs) = false

function parse_name_flags(name_or_flags::Tuple{Vararg{Union{Symbol,String}}})
    if length(name_or_flags) === 1 && Base.isidentifier(name_or_flags[1])
        name = String(name_or_flags[1])
        return name, nothing, String[]
    end

    flag_names, flags = extract_flag_names(name_or_flags)
    flag = longest(flags)
    name = longest(flag_names)

    return name, flag, flags
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

function remove_dashes(input_flag)
    first_non_dash = findfirst(!isequal('-'), input_flag)
    return first_non_dash - 1, input_flag[first_non_dash:end]
end

function longest(strs::Vector{String})
    idx = argmax(length.(strs))
    return strs[idx]
end

function coalesce_promote_types(types::DataType...)
    length(types) === 0 && return String

    ret_type = types[1]

    for type in types[2:end]
        if type !== Nothing
            ret_type = promote_type(ret_type, type)
        end
    end

    ret_type === Nothing && return String

    return ret_type
end

function validate_args(action, nargs, constant, default, type, choices, dest_is_vector)

    if action in [:store_true, :store_false, :store_const, :append_const]
        # Test that nargs and action are consistent
        if nargs !== nothing && nargs !== 0
            throw(ArgumentError("nargs=`$nargs` cannot be specified with action=`$action`"))
        end

        # Test that action and choices are consistent
        if choices !== nothing
            throw(ArgumentError("You do not need to specify `choices` for action=`$action`"))
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
    if !(action in [:store_true, :store_false, :store_const, :append, :append_const, :count])
        throw(ArgumentError("Invalid action: `$(String(action))`"))
    end
end

validate_nargs(nargs) = nothing
function validate_nargs(nargs::Char)
    if !(nargs in ['?', '+', '*'])
        throw(ArgumentError("Invalid specifier `$nargs` for `nargs`"))
    end
end

get_nargs(nargs::Nothing, ::Type{Bool}, action) = 0
get_nargs(nargs::Nothing, ::Type{Vector}, action) = '*'
get_nargs(nargs::Nothing, _, action) = action in [:store_const, :append_const] ? 0 : 1
get_nargs(nargs::Union{Int, Char}, _, _) = nargs
