const sqlitelib = find_library(["libsqlite3"], [get(ENV, "SEKELIA_SQLITE", [])])


function sqlite3_open(filename, handle)
    return ccall(
        (:sqlite3_open, sqlitelib),
        Cint,
        (Ptr{Uint8}, Ptr{Void}),
        filename,
        handle
    )
end

function sqlite3_errmsg(handle)
    return ccall(
        (:sqlite3_errmsg, sqlitelib),
        Ptr{Uint8},
        (Ptr{Void},),
        handle
    )
end
