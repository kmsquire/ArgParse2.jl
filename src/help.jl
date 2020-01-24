const NAME_FLAG_WIDTH = 12

function show_help(io::IO, parser::ArgumentParser; exit_when_done = !isinteractive())
    prog = something(parser.prog, cmdline_name)
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
            print_arg_help(arg.name, help)
        end

        print(io, '\n')
    end

    if !isempty(parser.optional_args)
        print(io, "Optional arguments:\n")

        for arg in parser.optional_args
            flags = format_flags(arg, arg.nargs)
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
        print(io, "Usage: $prog [options]\n")
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

function format_flags(arg::Argument, nargs)
    nargs = args.nargs
    nargs === 0 && return join(arg.flags, ", ")

    flag_arg = something(arg.metavar, uppercase(arg.name))

    return join([format_flag(flag, nargs, flag_arg) for flag in arg.flags], ", ")
end

function format_flag(flag, nargs, flag_arg=nothing)
    nargs === 0 && return flag

    if nargs isa Integer
        flag_args = join(fill(flag_arg, arg.nargs), " ")
        return "$flag $flag_args"
    end

    arg.nargs === '?' && return "$flag [$flag_arg]"
    arg.nargs === '*' && return "$flag [$flag_arg [$flag_arg ...]]"
    arg.nargs === '+' && return "$flag $flag_arg [$flag_arg ...]"

    throw(ArgumentError("Unexpected value for nargs: $(nargs)"))
end
