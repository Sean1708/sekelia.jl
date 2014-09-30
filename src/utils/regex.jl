function regex(context, nargs, values)
    rgx_val = unsafe_load(values::Ptr{Ptr{Void}}, 1)
    rgx = bytestring(
        ccall(
            (:sqlite3_value_text, api.SQLITELIB),
            Ptr{Uint8},
            (Ptr{Void},),
            rgx_val
        )
    )

    str_val = unsafe_load(values::Ptr{Ptr{Void}}, 2)
    str = bytestring(
        ccall(
            (:sqlite3_value_text, api.SQLITELIB),
            Ptr{Uint8},
            (Ptr{Void},),
            str_val
        )
    )

    r = Regex(rgx)
    if ismatch(r, str)
        ccall(
            (:sqlite3_result_int, api.SQLITELIB),
            Void,
            (Ptr{Void}, Cint),
            context,
            1
        )
    else
        ccall(
            (:sqlite3_result_int, api.SQLITELIB),
            Void,
            (Ptr{Void}, Cint),
            context,
            0
        )
    end

    nothing
end

function registerfunc(db, name, func, nargs)
    cfunc = cfunction(func, Nothing, (Ptr{Void}, Cint, Ptr{Ptr{Void}}))

    err = ccall(
        (:sqlite3_create_function, api.SQLITELIB),
        Cint,
        (Ptr{Void}, Ptr{Uint8}, Cint, Cint,
         Ptr{Void}, Ptr{Void}, Ptr{Void}, Ptr{Void}),
        db,
        name,
        nargs,
        1 | 0x800,
        C_NULL,
        cfunc,
        C_NULL,
        C_NULL
    )

    if err != api.SQLITE_OK
        error("could not register function $(name): $(api.sqlite3_errstr(err))")
    end
end
