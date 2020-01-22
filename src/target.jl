struct Target{T}
    value::Optional{T}
    count::Int16
end

function empty_arg_state(arg::Argument{T}) where T
    if arg.nargs == 1
        return Target{T}(arg.default, 0)
    else
        return Target{Vector{T}}(T[], 0)
    end
end
