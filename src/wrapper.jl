const SQLITELIB = find_library(["libsqlite3"], [get(ENV, "SEKELIA_SQLITE", [])])

const SQLITE_OK = 0


function sqlite3_open(file)
    #=
     Create or open SQLite3 database.

     Handle all memory allocations and any errors that occur and return only the
     handle to the database.
    =#
    handle_ptr = Array(Ptr{Void}, 1)
    err = ccall(
        (:sqlite3_open, SQLITELIB),
        Cint,
        (Ptr{Uint8}, Ptr{Void}),
        file,
        handle_ptr
    )

    handle = handle_ptr[1]
    if err != SQLITE_OK
        error("unable to open $(file): $(sqlite3_errmsg(handle))")
    else
        return handle
    end
end

function sqlite3_close(db)
    #=
     Close database pointed to by handle.
    =#
    err = ccall(
        (:sqlite3_close_v2, SQLITELIB),
        Cint,
        (Ptr{Void},),
        db.handle
    )

    if err != SQLITE_OK
        warn("error closing $(db.name): $(sqlite3_errmsg(db.handle))")
    end
end

function sqlite3_errmsg(handle)
    #=
     Query error message from database pointed to by handle.

     Return the message converted to String.
    =#
    return bytestring(
        ccall(
            (:sqlite3_errmsg, SQLITELIB),
            Ptr{Uint8},
            (Ptr{Void},),
            handle
        )
    )
end
