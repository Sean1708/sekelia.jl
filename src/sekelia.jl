module sekelia


export SPECIALDB, connectdb, close

include("types.jl")
include("constants.jl")

module wrapper
include("wrapper.jl")
end

module utils
include("utils.jl")
end


function connect(file=SPECIALDB.memory)
    #=
     Connect to and return the specified SQLite database.

     If the file is SPECIALDB.memory a temporary in-memory database will be
     created. If the file is SPECIALDB.disk a temporary on-disk database will
     be created.
    =#
    file = utils.fixfilename(file)

    handle_ptr = Array(Ptr{Void}, 1)
    err = wrapper.sqlite3_open(file, handle_ptr)
    handle = handle_ptr[1]

    if err != SQLITE_OK
        error("unable to open $(file): $(wrapper.sqlite3_errstr(err))")
    else
        return SQLiteDB(file, handle)
    end
end
# avoid name clashes with predefined connect
connectdb = connect

function close(db::SQLiteDB)
    #=
     Close the database connection and cause the handle to be unusable.
    =#
    err = wrapper.sqlite3_close_v2(db.handle)

    if err != SQLITE_OK
        warn("error closing $(db.name): $(wrapper.sqlite3_errstr(err))")
    end
end


end  # module
