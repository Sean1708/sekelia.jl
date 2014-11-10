**THIS PACKAGE IS NO LONGER ACTIVELY DEVELOPED, PLEASE SEE THE OFFICIAL SQLITE PACKAGE (quinnj/SQLite.jl)**


# sekelia

[![Build Status](https://travis-ci.org/Sean1708/sekelia.jl.svg?branch=master)](https://travis-ci.org/Sean1708/sekelia.jl)

A Julia package for interacting with the SQLite3 Library. Sekelia tries (and
probably fails) to provide a powerful interface without performing too much
"magic" behind the scenes.


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


## Documentation

The main object in sekelia is the SQLiteDB, it is defined as follows

    type SQLiteDB <: Database
        name::String
        handle::Ptr{Void}
    end

`name` is the String which is passed to the `sqlite3_open` C library function.
`handle` is the `sqlite3*` which is returned by the same function. Custom
database objects can be defined but they must be a subtype of `Database` and
contain both fields which `SQLiteDB` contains. 

Sekelia also exports 7 functions and 2 constants into the global scope, these are
explained below.

### Connecting to the database

    connectdb(file)
    sekelia.connect(file)

Open or create a database at the location specified by the string `file`. The
`SQLiteDB` object that is returned must be referenced for as long as it is open
to avoid Julia garbage collecting the handle, causing memory leaks. If `file`
is the global constant `MEMDB` then an in-memory database will be opened. If
`file` is the global constant `DISKDB` then a temporary on-disk database will
be opened.

### Closing the database

    close(db::Database)

Close the database referenced by the Database `db`.

### Executing a single statement

    execute(db::Database, stmt::String, values=(); header=false, types=false)

Execute the SQL statement `stmt`. If `stmt` contains multiple SQL statements
`execute` will throw an error, this helps protect against SQL Injection and
vastly simplifies the implementation.

If the statement returns any results (e.g. a SELECT statement) `execute` will
return an iterator which can be used in a `for-loop` or turned into an array
using `collect`. Each row is represented by a tuple of values. If you wish to
iterate manually using `consume` you must call it once more than the number of
rows to ensure memory is properly freed.

If `header` is true the first row produced will contain the titles of each column
in the result set. If `types` is true the first or second (depending on whether
`header` is true) row will be the Julia types of each column. The types are
inferred from the first row so in certain circumstances may not accurately
represent the types returned by later rows.

You can use values contained in Julia variables in your SQL statements using
SQLite's [parameter substitution](http://www.sqlite.org/c3ref/bind_blob.html).
If the statement uses nameless parameters (? or ?NNN) then `values` must be a
tuple where the first element will be put in place of ?1 etc. For example

    execute(db, "INSERT INTO table VALUES (?2, ?3, ?1)", ("a", "b", "c"))

is identical to

    execute(db, "INSERT INTO table VALUES ('b', 'c', 'a')")

If no numbers are appended to the question marks then the first element will be
put in place of the first question mark, etc.

If the statement uses named parameters (:VVV, @VVV or $VVV (this final form is
not recommended since you would have to remember to escape the $ each time))
then `values` must be a dictionary which maps a string or symbol to the value.
Some examples are

    # using Dict(S <: String, V} where V is any type (but not necessarily of type Any)
    execute(
        db,
        """INSERT INTO testtable VALUES (:a, @b, \$c, :d)""",
        ["a" => "Fourth row.", "b" => 4, "c" => 4.4, "d" => Uint8[4, 4, 4]]
    )
    # using Dict{Symbol, V}
    execute(
        db,
        """INSERT INTO testtable VALUES (:a, :b, :c, :d)""",
        [:a => "Fifth row.", :b => 5, :c => 5.5, :d => Uint8[5, 5, 5]]
    )
    
Dictionary keys can be a mix of Strings and Symbols but this method is slow so
should be avoided where possible.

### Executing multiple statments

    execute(db::Database, stmt::String, values::Vector{(Any...,)})
    execute{S, T}(db::Database, stmt::String, values::Vector{Dict{S, T}})

When `values` is a Vector (1-D Array) of the tuples or dictionaries described
above the statement is executed once for each tuple or dictionary in the Vector.
The body of the function is quite simply

    for tup in values
        execute(db, stmt, tup)
    end

### Custom parameter substitution

    bind(stmt, i, ::Nothing) # => NULL
    bind(stmt, i, val::Int32) # => INTEGER
    bind(stmt, i, val::Int64) # => INTEGER
    bind(stmt, i, val::Float64) # => REAL
    bind(stmt, i, val::String) # => TEXT
    bind(stmt, i, val::Ptr{Void}, n) # => BLOB

When parameter substitution is used one of the above bind methods is called to
coerce the values into a SQLite3 Datatype. You can define your own bind method
to store arbitrary datatypes in the way you want, the only stipulation being
that the last step in that method is to call one of the above methods. As an
example look at the definition for `bind(stmt, i, val::Integer)`

    function bind(stmt, i, val::Integer)
        if WORD_SIZE == 64
            bind(stmt, i, int64(val))
        else
            bind(stmt, i, int32(val))
        end
    end

This simply stores integers as the native system Int. Note that this is lossy
for Int128 (among others) so you might want to store this as TEXT by defining
the following method

    bind(stmt, i, val::Int128) = bind(stmt, i, string(val))

Another important factor to consider is that, since SQLite copies the memory
non-recursively, you can not store pointers to pointers in BLOBS (or any other
datatype). This means, among other things, that any multi-dimensional arrays
that you store must be flattened like in the following definition

    function bind{T}(stmt, i, val::Array{T})
        flat = reshape(val, length(val))
        nbytes = sizeof(flat)
        bind(stmt, i, convert(Ptr{Void}, flat), nbytes)
    end

To see which methods have been defined, please see src/utils/bind.jl in the
source code.

### Transactions

    transaction(db, mode="DEFERRED")

If mode is one of "", "DEFERRED", "IMMEDIATE" or "EXCLUSIVE" a transaction of
that [type](http://www.sqlite.org/lang_transaction.html) will be started.
Otherwise a [savepoint](http://www.sqlite.org/lang_savepoint.html) will be
created whose name is `mode` converted to a String via interpolation.

There is an alternative definition of `transaction` which takes a function as
it's first argument.

    transaction(f::Function, db)

Designed to be used with the do-block syntax this function will begin a
transaction then perform the function `f`. If `f` throws an error the
transaction will be rolled back otherwise the transaction will be committed. An
example would be

    execute(db, "CREATE TABLE tab (str TEXT);")
    execute(db, "INSERT INTO tab VALUES ('Only row.')")
    transaction(db) do
        execute(db, "INSERT INTO tab VALUES ('Will not be inserted.')")
        # multiple statements raises an error
        execute(db, "INSERT INTO tab VALUES (NULL); DROP TABLE tab")
    end
    for row in execute(db, "SELECT * FROM tab")
        println(row)
    end
    # ("Only row.",)

This is implemented using savepoints so you can safely nest it if you wish.

### Committing transactions

    commit(db)
    commit(db, name)

In the first form commits the curent transaction, in the second form releases
the savepoint `name`.

### Rollbacks

    rollback(db)
    rollback(db, name)

Either rolls back the current transaction or rolls back the transaction to the
savepoint `name`.
