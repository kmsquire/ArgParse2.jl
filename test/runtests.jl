using ArgParse2
using Test

function Base.redirect_stdout(f::Function, buf::Base.GenericIOBuffer)
    old_stdout = stdout
    try
        rd, = redirect_stdout()
        ret = f()
        Libc.flush_cstdio()
        flush(stdout)
        write(buf, readavailable(rd))
        return ret
    finally
        redirect_stdout(old_stdout)
    end
end

@testset "Smoke Test" begin
    parser = ArgumentParser(prog = "PROG", description="Smoke Test", epilog="Just testing smoke")
    add_argument! = argument_adder(parser)

    add_argument!("-f", "--foo")
    add_argument!("bar")

    @test parse_args(parser, ["BAR"]) === (bar = "BAR", foo = nothing)
    @test parse_args(parser, ["BAR", "--foo", "FOO"]) === (bar = "BAR", foo = "FOO")
    @test parse_args(parser, ["BAR", "--foo=FOO"]) === (bar = "BAR", foo = "FOO")
    @test_throws ArgumentError parse_args(parser, ["--foo", "FOO"])

    io = IOBuffer()

    redirect_stdout(io) do
        show_help(parser, exit_when_done=false)
        show_usage(parser)
    end
end

@testset "Action" begin
    @testset "Store1" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)

        add_argument!("--foo")

        @test parse_args(parser, split("--foo 1")) === (foo = "1",)
    end

    @testset "Store2" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)
        add_argument!("bar", nargs=2, type=Char)
        add_argument!("--foo", nargs=2)

        @test parse_args(parser, split("a b --foo d e")) == (bar = ['a', 'b'], foo = ["d", "e"])
    end

    @testset "Store Constant" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)

        add_argument!("--foo", action = "store_const", constant = 42)

        @test parse_args(parser, ["--foo"]) === (foo = 42,)
    end

    @testset "Store true/false" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)

        add_argument!("--foo", action = "store_true")
        add_argument!("--bar", action = "store_false")
        add_argument!("--baz", action = "store_false")

        @test parse_args(parser, split("--foo --bar")) === (foo = true, bar = false, baz = true)
    end

    @testset "Append" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)

        add_argument!("--foo", action = "append", default=["0"])

        @test parse_args(parser, split("--foo 1 --foo 2")) == (foo = ["0", "1", "2"],)
    end

    @testset "Append Constant" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)

        add_argument!("--str", dest = "types", action = "append_const", constant = String)
        add_argument!("--int", dest = "types", action = "append_const", constant = Int)

        @test parse_args(parser, split("--str --int")) == (types = [String, Int],)
    end

    @testset "Count" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)

        add_argument!("--verbose", "-v", action = "count", default = 0)

        @test parse_args(parser, ["-vvv"]) === (verbose = 3,)
    end

    @testset "Types" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)

        add_argument!("foo", type=Char)

        @test parse_args(parser, ["a"]) === (foo='a',)
        @test_throws ArgumentError parse_args(parser, ["abc"])
    end
end

@testset "Help" begin
    @testset "No help" begin
        parser = ArgumentParser(add_help = false)
        io = IOBuffer()
        show_help(io, parser, exit_when_done=false)
        output = String(take!(io)) |> rstrip

        @test output == "Usage: PROGRAM"
    end

    @testset "With help" begin
        parser = ArgumentParser()
        io = IOBuffer()
        show_help(io, parser, exit_when_done=false)
        output = String(take!(io)) |> rstrip |> x -> split(x, "\n") |> last |> lstrip

        @test output == "-h, --help   $(ArgParse2.HELP_TEXT)"
    end

    @testset "No Prog" begin
        parser = ArgumentParser(description="Test missing prog")
        add_argument!(parser, "foo")
        io = IOBuffer()
        show_help(io, parser, exit_when_done=false)
        output = String(take!(io)) |> x -> split(x, "\n") |> first

        @test output == "Usage: PROGRAM [-h] foo"
    end

    @testset "Prog" begin
        parser = ArgumentParser(prog="PROG", add_help = false)
        io = IOBuffer()
        show_help(io, parser, exit_when_done=false)
        output = String(take!(io)) |> rstrip

        @test output == "Usage: PROG"
    end

    @testset "Description" begin
        parser = ArgumentParser(add_help = false,
            description = """Frob the knob in the best way possible.
            Frobbing is an important step to take before fooing a bar,
            and is used in many fields when studying isoceles triangles
            in the wild.""")
        io = IOBuffer()
        show_help(io, parser, exit_when_done=false)
        output = String(take!(io)) |> rstrip

        @test output == ("""
        Usage: PROGRAM

        Frob the knob in the best way possible. Frobbing is an important step
        to take before fooing a bar, and is used in many fields when studying
        isoceles triangles in the wild.
        """ |> rstrip)
    end

    @testset "Usage" begin
        parser = ArgumentParser(usage = "PROG [options]", add_help=false)
        io = IOBuffer()
        show_usage(io, parser)
        output = String(take!(io)) |> rstrip

        @test output == "Usage: PROG [options]"
    end

    @testset "Multiple Arguments" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)
        add_argument!("foo", nargs=2)
        add_argument!("-b", nargs="?")
        add_argument!("-a", nargs="*")
        add_argument!("-r", nargs="+")

        io = IOBuffer()
        show_help(io, parser, exit_when_done=false)
        output=String(take!(io)) |> rstrip

        @test output == rstrip("""
        Usage: PROGRAM [-h] [-b [B]] [-a [A [A ...]]] [-r R [R ...]] foo foo

        Positional arguments:
         foo          foo help

        Optional arguments:
         -h, --help   show this help message and exit
         -b [B]       b help
         -a [A [A ...]]
                      a help
         -r R [R ...]
                      r help
        """)
    end
end

@testset "Arguments" begin
    @testset "Negative numerical arguments (1)" begin
        parser = ArgumentParser(prog="PROG")
        add_argument! = argument_adder(parser)

        add_argument!("-x")
        add_argument!("foo", nargs='?')

        # no negative number options, so -1 is a positional argument
        @test parse_args(parser, ["-x", "-1"]) === (foo=nothing, x="-1")

        # no negative number options, so -1 and -5 are positional arguments
        @test parse_args(parser, ["-x", "-1", "-5"]) === (foo="-5", x="-1")

    end

    @testset "Negative numerical arguments (1)" begin
        parser = ArgumentParser(prog="PROG")
        add_argument! = argument_adder(parser)
        add_argument!("-1", dest="one")
        add_argument!("foo", nargs='?')

        # negative number options present, so -1 is an option
        @test parse_args(parser, ["-1", "X"]) === (foo=nothing, one="X")

        # negative number options present, so -2 is an option
        @test_throws KeyError parse_args(parser, ["-2"])

        # negative number options present, so both -1s are options
        @test_throws ArgumentError parse_args(parser, ["-1", "-1"])
    end

    @testset "Multiple Arguments" begin
        @testset "?" begin
            parser = ArgumentParser()
            add_argument! = argument_adder(parser)
            add_argument!("bar", nargs="?")
            add_argument!("-f", nargs="?")

            @test parse_args(parser, []) === (bar=nothing, f=nothing)
            @test parse_args(parser, ["-f"]) === (bar=nothing, f=nothing)
            @test parse_args(parser, ["-f", "-1"]) === (bar=nothing, f="-1")
            @test parse_args(parser, ["-f", "-1", "-2"]) === (bar="-2", f="-1")
            @test parse_args(parser, ["a", "-f", "-1"]) === (bar="a", f="-1")
        end

        @testset "*" begin
            parser = ArgumentParser()
            add_argument! = argument_adder(parser)
            add_argument!("bar", nargs="*")
            add_argument!("-f", nargs="*")

            # Python's behavior
            @test_broken parse_args(parser, []) == (bar=nothing, f=nothing)
            @test_broken parse_args(parser, ["-f"]) == (bar=nothing, f=nothing)
            @test_broken parse_args(parser, ["-f", "-1"]) == (bar=nothing, f=["-1"])
            @test_broken parse_args(parser, ["-f", "-1", "-2"]) == (bar=nothing, f=["-1", "-2"])

            @test parse_args(parser, []) == (bar=[], f=[])
            @test parse_args(parser, ["-f"]) == (bar=[], f=[])
            @test parse_args(parser, ["-f", "-1"]) == (bar=[], f=["-1"])
            @test parse_args(parser, ["-f", "-1", "-2"]) == (bar=[], f=["-1", "-2"])
            @test parse_args(parser, ["a", "-f", "-1", "-2"]) == (bar=["a"], f=["-1", "-2"])
            @test parse_args(parser, ["a", "b", "c", "-f", "-1", "-2"]) == (bar=["a", "b", "c"], f=["-1", "-2"])
        end

        @testset "+ (1)" begin
            parser = ArgumentParser()
            add_argument! = argument_adder(parser)
            add_argument!("-f", "--foo", nargs="+")

            # Python's behavior
            @test_broken parse_args(parser, ["a"]) == (foo=nothing)

            @test parse_args(parser, []) == (foo=[],)
            @test_throws ArgumentError parse_args(parser, ["-f"])
        end

        @testset "+ (2)" begin
            parser = ArgumentParser()
            add_argument! = argument_adder(parser)
            add_argument!("bar", nargs="+")
            add_argument!("-f", "--foo", nargs="+")

            @test_throws ArgumentError parse_args(parser, [])
            # Python's behavior
            @test_broken parse_args(parser, ["a"]) == (bar=["a"], foo=nothing)

            @test parse_args(parser, ["a"]) == (bar=["a"], foo=[])

            @test_throws ArgumentError parse_args(parser, ["a", "-f"])

            @test parse_args(parser, ["a", "-f", "-1"]) == (bar=["a"], foo=["-1"],)
            @test parse_args(parser, ["a", "b", "c", "-f", "-1", "-2"]) == (bar=["a", "b", "c"], foo=["-1", "-2"],)
        end

        @testset "?*" begin
            parser = ArgumentParser()
            add_argument! = argument_adder(parser)
            add_argument!("foo", nargs="?")
            add_argument!("bar", nargs="*")

            @test parse_args(parser, []) == (foo=nothing, bar=[])
            @test parse_args(parser, ["a"]) == (foo="a", bar=[])
            @test parse_args(parser, ["a", "b", "c"]) == (foo="a", bar=["b", "c"])
        end
    end

    @testset "Choices" begin
        @testset "Array" begin
            parser = ArgumentParser()
            add_argument! = argument_adder(parser)
            add_argument!("move", choices=["rock", "paper", "scissors"])

            @test parse_args(parser, ["rock"]) === (move="rock",)
            @test_throws ArgumentError parse_args(parser, ["fire"])
        end

        @testset "Range" begin
            parser = ArgumentParser()
            add_argument! = argument_adder(parser)
            add_argument!("count", choices=1:3)

            @test parse_args(parser, ["1"]) === (count=1,)
            @test_throws ArgumentError parse_args(parser, ["4"])
        end
    end

    @testset "Dest1" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)
        add_argument!("-a", action="append", dest="dest", default=["a"])
        add_argument!("-b", action="append", dest="dest", default=["a"])
        @test parse_args(parser, []) == (dest=["a"],)
        @test parse_args(parser, split("-a c -b d")) == (dest=["c", "d"],)
    end

    @testset "Dest2" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)
        add_argument!("-a", action="append", dest="dest", default=["a"])
        add_argument!("-b", action="append", dest="dest", default=["b"])
        @test_throws ArgumentError parse_args(parser, [])
    end

    @testset "Required Options" begin
        parser = ArgumentParser()
        add_argument! = argument_adder(parser)
        add_argument!("-f", required=true)

        @test_throws ArgumentError parse_args(parser, [])
        @test parse_args(parser, ["-f", "foo"]) === (f="foo",)
    end
end

@testset "Construction Errors" begin
    parser = ArgumentParser()
    add_argument! = argument_adder(parser)
    @test_throws ArgumentError add_argument!("---foo")
    @test_throws ArgumentError add_argument!("-f", nargs="=")

    @test_throws ArgumentError add_argument!("-t", action="store_true", nargs=1)
    @test_throws ArgumentError add_argument!("-f", action="store_false", nargs=1)
    @test_throws ArgumentError add_argument!("-c", action="store_const", nargs=1, constant=1)
    @test_throws ArgumentError add_argument!("-a", action="append_const", nargs=1, constant=1)
    @test_throws ArgumentError add_argument!("-c", action="count", nargs=1)

    @test_throws ArgumentError add_argument!("-c", action="store_const")
    @test_throws ArgumentError add_argument!("-c", action="append_const")

    @test_throws ArgumentError add_argument!("-a", nargs="*", default="aaa")
    @test_throws ArgumentError add_argument!("-c", choices=["a","b"], default="c")
    @test_throws ArgumentError add_argument!("-c", choices=["a","b"], default=["c"])

    @test_throws ArgumentError add_argument!("-a", action="nothing")
end

@testset "Argument/flag Formatting" begin
    @test ArgParse2.format_flag("--flag", 1, "FLAG") === "--flag FLAG"
    @test ArgParse2.format_flag("--flag", 2, "FLAG") === "--flag FLAG FLAG"
    @test ArgParse2.format_flag("--flag", :?, "FLAG") === "--flag [FLAG]"
    @test ArgParse2.format_flag("--flag", :*, "FLAG") === "--flag [FLAG [FLAG ...]]"
    @test ArgParse2.format_flag("--flag", :+, "FLAG") === "--flag FLAG [FLAG ...]"

    @test_throws ArgumentError ArgParse2.format_arg_name("name", :(=))
end

@testset "Misc" begin
    @test ArgParse2.to_symbol(1) === 1
    for action in [:store_true, :store_false, :store_const, :append_const, :count]
        @test_throws ArgumentError ArgParse2.validate_args(
            action, nothing, nothing, nothing, nothing, ["true", "false"], false
        )
    end
    @test ArgParse2.validate_action("hi") === nothing
    @test ArgParse2.validate_nargs(1) === nothing
    @test ArgParse2.get_nargs(nothing, Bool, :store_true) === 0
    @test ArgParse2.get_nargs(nothing, Vector{String}, nothing) === :*
    @test ArgParse2.get_nargs(1, String, nothing) === 1
    @test ArgParse2.get_nargs(:*, String, nothing) === :*
    @test ArgParse2.get_nargs(:+, String, nothing) === :+
    @test ArgParse2.parse_item(String, "somestring", :arg) == "somestring"
    @test_throws ArgumentError ArgParse2.process_zero_arg_flag(nothing, :bad_action, nothing, nothing, nothing, nothing)

    parser = ArgumentParser(description="Test missing prog")
    @test_logs (:warn, r"add_argument\(...\) is deprecated.*") add_argument(parser, "foo")
    @test parse_args(parser, ["bar"]) === (foo = "bar",)
end

nothing
