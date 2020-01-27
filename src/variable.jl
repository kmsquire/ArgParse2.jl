mutable struct Variable{T,U <: Union{Vector{T},Optional{T},T}}
    value::U
    default_value::U
end

function get_value(v::Variable{T,Vector{T}}) where T
    !isempty(v.value) && return v.value
    return v.default_value
end

function get_value(v::Variable)
    v.value !== nothing && return v.value
    return v.default_value
end

set_value(v::Variable{T,Vector{T}}, arg) where T = push!(v.value, arg)
set_value(v::Variable, arg) = (v.value = arg)

function empty_var(arg::Argument{T,<:Any,V}) where {T,V}
    dest_is_vector = V
    if dest_is_vector
        default = arg.default !== nothing ? arg.default : T[]
        value = arg.action in [:append, :append_const] ? copy(default) : T[]
        return Variable{T,Vector{T}}(value, default)
    end

    if arg.action === :count
        default = arg.default !== nothing ? arg.default : 0
        return Variable{T,T}(arg.default, arg.default)
    end

    return Variable{T,Optional{T}}(nothing, arg.default)
end

function promote_var(arg1::Variable{S,V1}, arg2::Variable{T,V2}) where {S,T,V1,V2}
    if ((V1 <: AbstractVector && !(V2 <: AbstractVector)) ||
        (V2 <: AbstractVector && !(V1 <: AbstractVector)))

        throw(ArgumentError("Multiple arguments target the same destination variable,\n" *
        "but one accepts multiple values, and the other only accepts single values"))
    end

    if (arg1.default_value !== nothing && arg2.default_value !== nothing &&
        arg1.default_value != arg2.default_value)
        throw(ArgumentError("Multiple arguments target the same destination variable,\n" *
        "but have different default values(`$(arg1.default_value)` != `$(arg2.default_value)`"))
    end

    default_value = something(arg1.default_value, Some(arg2.default_value))

    U = promote_type(S, T)
    dest_is_vector = V1 <: AbstractVector

    if dest_is_vector
        return Variable{U,Vector{U}}(U[], default_value)
    end

    return Variable{U,Optional{U}}(nothing, default_value)
end
