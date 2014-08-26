using ..SQLITELIB


function sqlite3_open(file, handle_ptr)
    #=
     Create or open SQLite3 database.
    =#
    return int(
        ccall(
            (:sqlite3_open, SQLITELIB),
            Cint,
            (Ptr{Uint8}, Ptr{Void}),
            file,
            handle_ptr
        )
    )
end

function sqlite3_close_v2(handle)
    #=
     Close database pointed to by handle.
    =#
    return int(
        ccall(
            (:sqlite3_close_v2, SQLITELIB),
            Cint,
            (Ptr{Void},),
            handle
        )
    )
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

function sqlite3_errstr(errcode)
    #=
     Return the error message which describes errcode as a String.
    =#
    return bytestring(
        ccall(
            (:sqlite3_errstr, SQLITELIB),
            Ptr{Uint8},
            (Cint,),
            errcode
        )
    )
end
