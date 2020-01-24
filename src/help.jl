const NAME_FLAG_WIDTH = 12

function show_help(io::IO, parser::ArgumentParser; exit_when_done = !isinteractive())
    show_usage(io, parser)
    print(io, '\n')

    if parser.description !== nothing
        print(io, parser.description)
        print(io, '\n')
    end

    if !isempty(parser.positional_args)
        print(io, "Positional arguments:\n")

        for arg in parser.positional_args
            help = something(arg.help, "$(arg.name) help")
            print_arg_help(io, arg.name, help)
        end

        print(io, '\n')
    end

    if !isempty(parser.optional_args)
        print(io, "Optional arguments:\n")

        for arg in parser.optional_args
            flags = format_flags(arg)
            help = something(arg.help, "$(arg.name) help")
            print_arg_help(io, flags, help)
        end

        print(io, '\n')
    end

    if parser.epilog !== nothing
        print(io, parser.epilog)
        print(io, '\n')
    end

    exit_when_done && exit(0)
    nothing
end

function show_usage(io::IO, parser::ArgumentParser)
    if parser.usage !== nothing
        print(io, "Usage: $(parser.usage)\n")
    else
        cmdline_name = length(ARGS) > 0 ? ARGS[1] : "PROGRAM"
        prog = something(parser.prog, cmdline_name)
        options_str = join((format_flag(arg) for arg in parser.optional_args), ' ')
        params_str = join((format_arg_name(arg, to_uppercase=false) for arg in parser.positional_args), ' ')

        print(io, "Usage: $prog")
        !isempty(options_str) && print(io, " $options_str")
        !isempty(params_str) && print(io, " $params_str")
        print(io, '\n')
    end
end

show_usage(parser::ArgumentParser) = show_usage(stdout::IO, parser)

function print_arg_help(io, name_or_flags::AbstractString, help::AbstractString)
    print(io, ' ')
    print(io, name_or_flags)

    if length(name_or_flags) < NAME_FLAG_WIDTH
        pad = NAME_FLAG_WIDTH - length(name_or_flags)
        print(io, ' '^pad)
    else
        print(io, '\n')
        print(io, ' '^(NAME_FLAG_WIDTH + 2))
    end

    print(io, help)
    print(io, '\n')
end

show_help(parser::ArgumentParser; exit_when_done::Bool = !isinteractive()) =
    show_help(stdout::IO, parser, exit_when_done=exit_when_done)

function format_flags(arg::Argument)
    arg.nargs === 0 && return join(arg.flags, ", ")
    return join([format_flag(flag, arg.nargs, arg_name(arg), arg.required) for flag in arg.flags], ", ")
end

format_flag(arg::Argument) = format_flag(arg.default_flag, arg.nargs, arg_name(arg), arg.required)

function format_flag(flag, nargs, arg_name, required)
    nargs === 0 && return flag
    flag_name_str = format_arg_name(arg_name, nargs, required)
    return "$flag $flag_name_str"
end

format_arg_name(arg::Argument, to_uppercase::Bool=true) =
    format_arg_name(arg_name(arg, to_uppercase), arg.nargs, args.required)

function format_arg_name(name, nargs::Integer, required)
    required && return join(fill(name, nargs), " ")
    return "[$(join(fill(name, nargs), " "))]"
end

function format_arg_name(name, nargs, required)
    nargs === :? && return "[$name]"
    nargs === :* && return "[$name [$name ...]]"
    nargs === :+ && return "$name [$name ...]"

    throw(ArgumentError("Unexpected value for nargs: $(nargs)"))
end

