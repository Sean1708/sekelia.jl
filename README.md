# sekelia

[![Build Status](https://travis-ci.org/Sean1708/sekelia.jl.svg?branch=master)](https://travis-ci.org/Sean1708/sekelia.jl)

A simple package for interacting with SQLite databases from Julia.


## Installation

First ensure that your system has a version of both julia and SQLite or
download them yourself. Next open up an interactive prompt of julia and type

    Pkg.clone("git://github.com/Sean1708/sekelia.jl.git")

and you will be raring to go.

If your SQLite library is not in your system's path then place the following
line in your `~/.bash_profile`

    export SEKELIA_SQLITE=/path/to/sqlite/library/directory

where `/path/to/sqlite/library/directory` is the absolute path of the directory
containing your SQLite library.
