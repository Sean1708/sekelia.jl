const sqlitelib = find_library(["libsqlite3"], [get(ENV, "SEKELIA_SQLITE", [])])


function sqlite3_open(filename, handle)
    #=
     Create or open SQLite3 database.

     Return error code.
    =#
    return ccall(
        (:sqlite3_open, sqlitelib),
        Cint,
        (Ptr{Uint8}, Ptr{Void}),
        filename,
        handle
    )
end

function sqlite3_errmsg(handle)
    #=
     Query error message from database pointed to by handle.

     Return the message converted to String.
    =#
    return bytestring(
        ccall(
            (:sqlite3_errmsg, sqlitelib),
            Ptr{Uint8},
            (Ptr{Void},),
            handle
        )
    )
end
