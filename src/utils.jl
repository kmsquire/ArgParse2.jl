function remove_dashes(input_flag)
    first_non_dash = findfirst(!isequal('-'), input_flag)
    return first_non_dash - 1, input_flag[first_non_dash:end]
end

function longest(strs::Vector{String})
    idx = argmax(length.(strs))
    return strs[idx]
end

function is_numeric(flag::String)
    return tryparse(Float64, flag) !== nothing
end
