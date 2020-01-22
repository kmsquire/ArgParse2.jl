using ArgParse2
using Test

@testset "ArgParse2.jl" begin
    parser = ArgumentParser(prog = "ArgParse2Tests",
        usage = "]test Argparse2",
        description = "Argparse2 Tests",
        epilog = "Epilog",
        add_help = true,
    )
    println(parser)
end
