module sekelia

const sqlitelib = find_library(["libsqlite3"], [get(ENV, "SEKELIA_SQLITE", [])])

type SQLiteDB
    filename::String
    handle::Ptr{Void}
end

function _sqlite3_open(filename, handle)
    return ccall(
        (:sqlite3_open, sqlitelib),
        Cint,
        (Ptr{Uint8}, Ptr{Void}),
        filename,
        handle
    )
end

function _sqlite3_errmsg(handle)
    return ccall(
        (:sqlite3_errmsg, sqlitelib),
        Ptr{Uint8},
        (Ptr{Void},),
        handle
    )
end

function connect(filename=nothing)
    #=
     Connect to and return the specified SQLite database.

     If no filename is given a temporary database will be created in memory. If
     the filename is given as an empty string a temporary database will be
     created on disk.
    =#
    if is(filename, nothing)
        filename = ":memory"
    elseif beginswith(filename, ':')
        # may cause problems with future versions of SQLite otherwise
        filename = "./" * filename
    end

    handle_ptr = Array(Ptr{Void},1)
    err = _sqlite3_open(filename, handle_ptr)
    handle = handle_ptr[1]
    if err != 0
        error("can't open $(file): $(_sqlite3_errmsg(handle))")
    else
        return SQLiteDB(filename, handle)
    end
end

end # module
