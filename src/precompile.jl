function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    precompile(Tuple{Core.kwftype(typeof(ArgParse2.add_argument!)),NamedTuple{(:action, :help),Tuple{String,String}},typeof(add_argument!),ArgumentParser,String,Vararg{String,N} where N})
    precompile(Tuple{Core.kwftype(typeof(ArgParse2.add_argument!)),NamedTuple{(:action, :help),Tuple{String,String}},typeof(add_argument!),ArgumentParser,String,Vararg{String,N} where N})
    precompile(Tuple{Core.kwftype(typeof(ArgParse2.show_help)),NamedTuple{(:exit_when_done,),Tuple{Bool}},typeof(show_help),Base.PipeEndpoint,ArgumentParser})

    @static if v"1.3" <= VERSION < v"1.4.0-rc1.0"
        precompile(Tuple{Core.var"#kw#Type",NamedTuple{(:action, :default),Tuple{String,Int64}},Type{ArgParse2.Argument},String,String})
        precompile(Tuple{Core.var"#kw#Type",NamedTuple{(:action, :help),Tuple{String,String}},Type{ArgParse2.Argument},String,String})
        precompile(Tuple{Core.var"#kw#Type",NamedTuple{(:nargs,),Tuple{String}},Type{ArgParse2.Argument},String,String})
        precompile(Tuple{Core.var"#kw#Type",NamedTuple{(:prog, :description, :epilog),Tuple{String,String,String}},Type{ArgumentParser}})
    end

    precompile(Tuple{typeof(ArgParse2.init_arg_variable),ArgParse2.Argument{DataType,Nothing,true},ArgParse2.Variable{DataType,Array{DataType,1}}})
    precompile(Tuple{typeof(ArgParse2.parse_cmdline_arg),String,ArgParse2.Variable{Int64,Union{Nothing,Int64}},UnitRange{Int64},String})
    precompile(Tuple{typeof(parse_args),ArgumentParser,Array{Any,1}})
    precompile(Tuple{typeof(parse_args),ArgumentParser,Array{String,1}})
    precompile(Tuple{typeof(parse_args),ArgumentParser,Array{SubString{String},1}})
    precompile(Tuple{typeof(ArgParse2.get_nargs),Nothing,Type,Symbol})
end
