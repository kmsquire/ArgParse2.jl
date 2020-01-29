const NAME_FLAG_WIDTH = 12
const ARG_HELP_INDENT = NAME_FLAG_WIDTH + 2

function show_help(io::IO, parser::ArgumentParser; exit_when_done = !isinteractive())
    show_usage(io, parser)
    println(io)

    if parser.description !== nothing
        println_wrapped(io, parser.description)
        println(io)
    end

    if !isempty(parser.positional_args)
        print(io, "Positional arguments:\n")

        for arg in parser.positional_args
            help = something(arg.help, "$(arg.name) help")
            print_arg_help(io, arg.name, help)
        end

        println(io)
    end

    if !isempty(parser.optional_args)
        print(io, "Optional arguments:\n")

        for arg in parser.optional_args
            flags = format_flags(arg)
            help = something(arg.help, "$(arg.name) help")
            print_arg_help(io, flags, help)
        end

        println(io)
    end

    if parser.epilog !== nothing
        println_wrapped(io, parser.epilog)
    end

    exit_when_done && exit(0)
    nothing
end

function show_usage(io::IO, parser::ArgumentParser)
    if parser.usage !== nothing
        println_wrapped(io, "Usage: $(parser.usage)\n"; subsequent_indent = ARG_HELP_INDENT, break_long_words = false)
    else
        cmdline_name = length(ARGS) > 0 ? ARGS[1] : "PROGRAM"
        prog = something(parser.prog, cmdline_name)
        options_str = join((format_usage_flag(arg) for arg in parser.optional_args), ' ')
        params_str = join((format_arg_name(arg, false) for arg in parser.positional_args), ' ')


        println_wrapped(io, "Usage: $prog $options_str $params_str"; subsequent_indent = ARG_HELP_INDENT, break_long_words = false)
    end
end

show_usage(parser::ArgumentParser) = show_usage(stdout::IO, parser)

function print_arg_help(io, name_or_flags::AbstractString, help::AbstractString)
    if length(name_or_flags) < NAME_FLAG_WIDTH
        pad = ARG_HELP_INDENT - length(name_or_flags) - 1  # the -1 at the end is for the initial space
        print(io, ' ', name_or_flags, ' '^pad)

        wrapped_help = wrap(help;
            initial_indent = ARG_HELP_INDENT,
            subsequent_indent = ARG_HELP_INDENT,) |> lstrip
        println(io, help)
    else
        println(io, ' ', name_or_flags)
        println_wrapped(io,
            help;
            initial_indent = ARG_HELP_INDENT,
            subsequent_indent = ARG_HELP_INDENT,)
    end
end

show_help(parser::ArgumentParser; exit_when_done::Bool = !isinteractive()) =
    show_help(stdout::IO, parser, exit_when_done = exit_when_done)

function format_flags(arg::Argument)
    arg.nargs === 0 && return join(arg.flags, ", ")
    return join([format_flag(flag, arg.nargs, arg_name(arg)) for flag in arg.flags], ", ")
end

format_usage_flag(arg::Argument) = format_usage_flag(arg.default_flag, arg.nargs, arg_name(arg), arg.required)

function format_usage_flag(flag, nargs, arg_name, required)
    required && return format_flag(flag, nargs, arg_name)
    return '[' * format_flag(flag, nargs, arg_name) * ']'
end

function format_flag(flag, nargs, arg_name)
    nargs === 0 && return flag
    flag_name_str = format_arg_name(arg_name, nargs)
    return "$flag $flag_name_str"
end

format_arg_name(arg::Argument, to_uppercase::Bool = true) =
    format_arg_name(arg_name(arg, to_uppercase), arg.nargs)

function format_arg_name(name, nargs::Integer)
    return join(fill(name, nargs), " ")
end

function format_arg_name(name, nargs)
    nargs === :? && return "[$name]"
    nargs === :* && return "[$name [$name ...]]"
    nargs === :+ && return "$name [$name ...]"

    throw(ArgumentError("Unexpected value for nargs: $(nargs)"))
end

