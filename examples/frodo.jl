#=
Frodo

Run in this directory with
    julia --project=.. frodo.jl Baggins \
        --auto-hide \
        --friends "Samwise Gangee" "Peregrin Took" "Meriadoc Brandybuck" "Fredegar Bolger"
=#

using ArgParse2

in_danger() = rand(Bool)

function julia_main()::Cint
    parser = ArgumentParser(description = "Welcome to Middle Earth",
                            epilog = "There is no real going back")

    add_argument(parser, "surname", help = "Your surname")
    add_argument(parser, "-s", "--ring-size", type = Int, help = "Ring size")
    add_argument(parser,
        "--auto-hide",
        action = "store_true",
        default = false,
        help = "Turn invisible when needed")
    add_argument(parser, "--friends", metavar="FRIEND", nargs = "+", required = true)

    args = parse_args(parser)

    println("Welcome, Frodo $(args.surname)!")
    if args.ring_size === nothing
        println("Let's get you fitted for a ring.  We'll need to measure your ring size.")
    else
        println("I see your ring size is $(args.ring_size)")
    end

    if in_danger() && args.auto_hide
        println("Orcs are near!  You turn invisible.")
    end

    if length(args.friends) > 0
        travel_companions = join(args.friends, ", ", " and ")
        println("You're traveling to Mordor with $travel_companions.")
    end

    return 0
end

julia_main()
