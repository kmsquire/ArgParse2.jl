# ArgParse2

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://kmsquire.github.io/ArgParse2.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://kmsquire.github.io/ArgParse2.jl/dev)
[![Build Status](https://travis-ci.com/kmsquire/ArgParse2.jl.svg?branch=master)](https://travis-ci.com/kmsquire/ArgParse2.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/kmsquire/ArgParse2.jl?svg=true)](https://ci.appveyor.com/project/kmsquire/ArgParse2-jl)
[![Coveralls](https://coveralls.io/repos/github/kmsquire/ArgParse2.jl/badge.svg?branch=master)](https://coveralls.io/github/kmsquire/ArgParse2.jl?branch=master)

## Installation

This package is not registered yet, but can be installed directly from this repo.
From the Julia REPL or in a Jupyter cell, run

```julia
]activate .  # Optionally activate a project
]add https://github.com/kmsquire/ArgParse2.jl
```

Or, equivalently, from the command line with

```bash
julia --project=. -e 'import Pkg; Pkg.add("https://github.com/kmsquire/ArgParse2.jl")'
```

(Remove `--project=.` if not working in a project... but you should be!)

## Overview

This is (another) argument parser for Julia, inspired by and based on Python's `argparse`
library.

At the time of this writing, there are two other argument parsers available.

1. [ArgParse.jl](https://github.com/carlobaldassi/ArgParse.jl/), also largely based on Python's
   [argparse module](https://docs.python.org/3/library/argparse.html).
2. [DocOpt.jl](https://github.com/docopt/DocOpt.jl), based on a the Python [docopt module](http://docopt.org/).

Both are actually quite feature full.  What I found was that the startup, compile, and
sometimes parse overhead were quite high for a project I was working on.  `ArgParse2.jl` was an
attempt to do better.

Some differences from `ArgParse.jl`:

* More closely copies the interface from Python's argparse.  In particular, all but one of the
  (supported) arguments to `ArgumentParser` and `add_argument` have the same names.  (`const`
  is a keyword in Julia, so that was renamed to `constant`)
* `ArgParse2.jl` uses functions instead of macros for setting up the parser, so the parsing
  setup is somewhat different.  Again, this is more similar to Python's `argparse`.
* `ArgParse2.jl` returns a `NamedTuple` object with the parsed arguments; `ArgParse.jl`
  returns a dictionary.  (`NamedTuples` did  not exist in the language when `ArgParse.jl` was written, but it's output could trivially be put into one.)

`DocOpt.jl` is quite different (and quite cool).  From my limited exploration, it doesn't
quite give the same level of control over argument behavior, but has the advantage of a much
more concise syntax.

## Example

```julia
using ArgParse2

in_danger() = rand(Bool)

function julia_main()::Cint
    parser = ArgumentParser(prog = "frodo",
                            description = "Welcome to Middle Earth",
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
```

## Status

At this point, `ArgParse2.jl` isn't feature full (e.g., commands are not implemented).
Load/compile time is currently is faster than both parsers mentioned above, and (from some
very minor testing) parse time is faster than `ArgParse.jl`  and about on par with `DocOpt.jl`
(for the features supported).  That will probably change as more features are added (it might
get slower).  There's probably room for optimization as well.

There's no documentation yet--for now, you can use the example above (also in the `examples`
directory) and the tests as guidelines.

If you're familiar with Python's argparse library,
this library should feel very familiar.
