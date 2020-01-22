@kwdef struct Argument{T}
    name::String
    flags::Vector{String}
    action::Optional{Symbol} = nothing
    nargs::Union{Int,Char} = 1
    constant::Optional{T} = nothing
    default::Optional{T} = nothing
    type::DataType = T
    choices::Optional{Vector{T}} = nothing
    required::Bool = false
    help::Optional{String} = nothing
    metavar::Optional{String} = nothing
    dest::Symbol
end

function Argument(name_or_flags::Union{Symbol,String}...;
    action::Union{Symbol,String,Nothing} = nothing,
    nargs::Union{Int,Char} = 1,
    constant::R = nothing,
    default::S = nothing,
    type::DataType = Nothing,
    choices::Union{Vector{T},T} = nothing,
    dest::Union{Symbol,String,Nothing} = nothing,
    kwargs...) where {R,S,T,U}

    name, flags = parse_name_flags(name_or_flags)
    if dest === nothing
        dest = name
    end

    A = type !== Nothing ? type : coalesce_promote_types(R, S, T)
    _action = action isa String ? Symbol(action) : action

    validate_nargs(nargs)

    Argument{A}(;
        name = name,
        flags = flags,
        action = _action,
        nargs = nargs,
        constant = constant,
        default = default,
        type = type,
        choices = choices,
        dest = Symbol(dest),
        kwargs...)
end

function parse_name_flags(name_or_flags::Tuple{Vararg{Union{Symbol,String}}})
    if length(name_or_flags) === 1
        name = String(name_or_flags[1])
        validate_name(name)
        return name, String[]
    end

    flag_names, flags = extract_flag_names(name_or_flags)
    name = extract_longest(flag_names)

    return name, flags
end

function validate_name(name)
    !Base.isidentifier(name) && throw(ArgumentError("Invalid argument: `$name`"))
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

function extract_longest(flag_names::Vector{String})
    idx = argmax(length.(flag_names))
    return flag_names[idx]
end

function coalesce_promote_types(types::DataType...)
    length(types) === 0 && return Any

    ret_type = types[1]

    for type in types[2:end]
        if type !== Nothing
            ret_type = promote_type(ret_type, type)
        end
    end

    ret_type === Nothing && return Any

    return ret_type
end

validate_nargs(nargs::Integer) = nothing
function validate_nargs(nargs::Char)
    !(nargs in ['?', '+', '*']) && throw(ArgumentError("Invalid specifier `$nargs` for `nargs`"))
    nothing
end
