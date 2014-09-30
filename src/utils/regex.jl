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
