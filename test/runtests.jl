using ArgParse2
using Test

@testset "Smoke Test" begin
    parser = ArgumentParser(prog = "PROG")
    add_argument = argument_adder(parser)

    add_argument("-f", "--foo")
    add_argument("bar")

    @test parse_args(parser, ["BAR"]) === (bar = "BAR", foo = nothing)
    @test parse_args(parser, ["BAR", "--foo", "FOO"]) === (bar = "BAR", foo = "FOO")
    @test_throws ArgumentError parse_args(parser, ["--foo", "FOO"])
end

@testset "Action" begin
    @testset "Store1" begin
        parser = ArgumentParser()
        add_argument = argument_adder(parser)

        add_argument("--foo")

        @test parse_args(parser, split("--foo 1")) === (foo = "1",)
    end

    @testset "Store2" begin
        parser = ArgumentParser()
        add_argument = argument_adder(parser)
        add_argument("bar", nargs=2, type=Char)
        add_argument("--foo", nargs=2)

        @test parse_args(parser, split("a b --foo d e")) == (bar = ['a', 'b'], foo = ["d", "e"])
    end

    @testset "Store Constant" begin
        parser = ArgumentParser()
        add_argument = argument_adder(parser)

        add_argument("--foo", action = "store_const", constant = 42)

        @test parse_args(parser, ["--foo"]) === (foo = 42,)
    end

    @testset "Store true/false" begin
        parser = ArgumentParser()
        add_argument = argument_adder(parser)

        add_argument("--foo", action = "store_true")
        add_argument("--bar", action = "store_false")
        add_argument("--baz", action = "store_false")

        @test parse_args(parser, split("--foo --bar")) === (foo = true, bar = false, baz = true)
    end

    @testset "Append" begin
        parser = ArgumentParser()
        add_argument = argument_adder(parser)

        add_argument("--foo", action = "append")

        @test parse_args(parser, split("--foo 1 --foo 2")) == (foo = ["1", "2"],)
    end

    @testset "Append Constant" begin
        parser = ArgumentParser()
        add_argument = argument_adder(parser)

        add_argument("--str", dest = "types", action = "append_const", constant = String)
        add_argument("--int", dest = "types", action = "append_const", constant = Int)

        @test parse_args(parser, split("--str --int")) == (types = [String, Int],)
    end

    @testset "Count" begin
        parser = ArgumentParser()
        add_argument = argument_adder(parser)

        add_argument("--verbose", "-v", action = "count", default = 0)

        @test parse_args(parser, ["-vvv"]) === (verbose = 3,)
    end
end

@testset "Test Help" begin
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
        output = String(take!(io)) |> rstrip

        @test occursin(Regex("-h, --help +$(ArgParse2.HELP_TEXT)\$"), output)
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
        output = String(take!(io))

        @test output === """
        Usage: PROGRAM

        Frob the knob in the best way possible. Frobbing is an important step
        to take before fooing a bar, and is used in many fields when studying
        isoceles triangles in the wild.
        """
    end
end

@testset "Miscellaneous" begin
    @testset "Arguments with '-' (1)" begin
        parser = ArgumentParser(prog="PROG")
        add_argument = argument_adder(parser)

        add_argument("-x")
        add_argument("foo", nargs='?')

        # no negative number options, so -1 is a positional argument
        @test parse_args(parser, ["-x", "-1"]) === (foo=nothing, x="-1")

        # no negative number options, so -1 and -5 are positional arguments
        @test parse_args(parser, ["-x", "-1", "-5"]) === (foo="-5", x="-1")

    end

    @testset "Arguments with '-' (2)" begin
        parser = ArgumentParser(prog="PROG")
        add_argument = argument_adder(parser)
        add_argument("-1", dest="one")
        add_argument("foo", nargs='?')

        # negative number options present, so -1 is an option
        @test parse_args(parser, ["-1", "X"]) === (foo=nothing, one="X")

        # negative number options present, so -2 is an option
        @test_throws KeyError parse_args(parser, ["-2"])

        # negative number options present, so both -1s are options
        @test_throws ArgumentError parse_args(parser, ["-1", "-1"])
    end
end

nothing
