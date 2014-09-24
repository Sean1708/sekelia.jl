using ..SQLITELIB
include("SQLite_consts.jl")


function sqlite3_open(file)
    #=
     Create or open SQLite3 database.
    =#
    handle_ptr = Array(Ptr{Void}, 1)
    err = ccall(
        (:sqlite3_open, SQLITELIB),
        Cint,
        (Ptr{Uint8}, Ptr{Void}),
        file,
        handle_ptr
    )
    if err != SQLITE_OK
        error("unable to open $(file): $(sqlite3_errstr(err))")
    else
        return handle_ptr[1]
    end
end

function sqlite3_close_v2(handle)
    #=
     Close database pointed to by handle.
    =#
    err = ccall(
        (:sqlite3_close_v2, SQLITELIB),
        Cint,
        (Ptr{Void},),
        handle
    )
    if err != SQLITE_OK
        warn("error closing $(db.name): $(sqlite3_errstr(err))")
    end
end

function sqlite3_prepare_v2(handle, query)
    #=
     Compile query to a byte-code program that can be executed.
    =#
    prepstmt_ptr = Array(Ptr{Void}, 1)
    err = ccall(
        (:sqlite3_prepare_v2, SQLITELIB),
        Cint,
        (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Void}, Ptr{Void}),
        handle,
        query,
        sizeof(query)+1,  # ensure NUL character is included
        prepstmt_ptr,
        [C_NULL]
    )
    if err != SQLITE_OK
        error("could not prepare statement: $(sqlite3_errstr(err))")
    else
        return prepstmt_ptr[1]
    end
end

function sqlite3_step(stmt)
    #=
     Evaluate previously compiled statement.
    =#
    err = ccall(
        (:sqlite3_step, SQLITELIB),
        Cint,
        (Ptr{Void},),
        stmt
    )
    if err == SQLITE_DONE || err == SQLITE_ROW
        return err
    else
        # ensure statement is finalised even on error
        sqlite3_finalize(stmt)
        error("error executing statement: $(sqlite3_errstr(err))")
    end
end

function sqlite3_column_count(stmt)
    #=
     Query number of columns in returned results.
    =#
    return int(
        ccall(
            (:sqlite3_column_count, SQLITELIB),
            Cint,
            (Ptr{Void},),
            stmt
        )
    )
end

function sqlite3_column_name(stmt, col)
    #=
     Query the name of column col.
    =#
    # sqlite is 0-indexed, julia ain't
    col -= 1
    return bytestring(
        ccall(
            (:sqlite3_column_name, SQLITELIB),
            Ptr{Uint8},
            (Ptr{Void}, Cint),
            stmt,
            col
        )
    )
end
        
function sqlite3_column_type(stmt, col)
    #=
     Query the type of column col.
    =#
    # sqlite is 0-indexed, julia ain't
    col -= 1
    return int(
        ccall(
            (:sqlite3_column_type, SQLITELIB),
            Cint,
            (Ptr{Void}, Cint),
            stmt,
            col
        )
    )
end

function sqlite3_column_double(stmt, col)
    #=
     Retrieve the value from column col in the current row coverted to double.
    =#
    # sqlite is 0-indexed, julia ain't
    col -= 1
    return float(
        ccall(
            (:sqlite3_column_double, SQLITELIB),
            Cdouble,
            (Ptr{Void}, Cint),
            stmt,
            col
        )
    )
end

function sqlite3_column_int(stmt, col)
    #=
     Retrieve the value from column col in the current row coverted to int32.
    =#
    # sqlite is 0-indexed, julia ain't
    col -= 1
    return int32(
        ccall(
            (:sqlite3_column_int, SQLITELIB),
            Cint,
            (Ptr{Void}, Cint),
            stmt,
            col
        )
    )
end

function sqlite3_column_int64(stmt, col)
    #=
     Retrieve the value from column col in the current row coverted to int64.
    =#
    # sqlite is 0-indexed, julia ain't
    col -= 1
    return int64(
        ccall(
            (:sqlite3_column_int64, SQLITELIB),
            Clonglong,
            (Ptr{Void}, Cint),
            stmt,
            col
        )
    )
end

function sqlite3_column_text(stmt, col)
    #=
     Retrieve the value from column col in the current row coverted to char*.

     Return the value as a julia String.
    =#
    # sqlite is 0-indexed, julia ain't
    col -= 1
    return bytestring(
        ccall(
            (:sqlite3_column_text, SQLITELIB),
            Ptr{Uint8},
            (Ptr{Void}, Cint),
            stmt,
            col
        )
    )
end

function sqlite3_column_blob(stmt, col)
    #=
     Retrieve the value from column col in the current row converted to char*.

     Return the value as a julia bytearray. The sqlite3_column_text function is
     used since the only conversion that happens from BLOB to TEXT is the
     addition of a nul-byte.
    =#
    # sqlite is 0-indexed, julia ain't
    col -= 1
    temparr = pointer_to_array(
        ccall(
            (:sqlite3_column_text, SQLITELIB),
            Ptr{Uint8},
            (Ptr{Void}, Cint),
            stmt,
            col
        ),
        ccall(
            (:sqlite3_column_bytes, SQLITELIB),
            Cint,
            (Ptr{Void}, Cint),
            stmt,
            col
        )
    )
    # return a deepcopy otherwise values in the array are prone to changing when
    # the statement is finalised
    return deepcopy(temparr)
end

function sqlite3_bind_parameter_count(stmt)
    #=
     Query number of variables in prepared statement.
    =#
    return int(
        ccall(
            (:sqlite3_bind_parameter_count, SQLITELIB),
            Cint,
            (Ptr{Void},),
            stmt
        )
    )
end

function sqlite3_bind_null(stmt, i)
    #=
     Bind Null to a parameter.
    =#
    err = ccall(
        (:sqlite3_bind_null, SQLITELIB),
        Cint,
        (Ptr{Void}, Cint),
        stmt,
        i
    )
    if err != SQLITE_OK
        sqlite3_finalize(stmt)
        error("could not bind parameter: $(sqlite3_errstr(err))")
    end
end

function sqlite3_bind_int(stmt, i, val)
    #=
     Bind an Int32 to a parameter.
    =#
    err = ccall(
        (:sqlite3_bind_int, SQLITELIB),
        Cint,
        (Ptr{Void}, Cint, Cint),
        stmt,
        i,
        val
    )
    if err != SQLITE_OK
        sqlite3_finalize(stmt)
        error("could not bind parameter: $(sqlite3_errstr(err))")
    end
end

function sqlite3_bind_int64(stmt, i, val)
    #=
     Bind an Int64 to a parameter.
    =#
    err = ccall(
        (:sqlite3_bind_int64, SQLITELIB),
        Cint,
        (Ptr{Void}, Cint, Clonglong),
        stmt,
        i,
        val
    )
    if err != SQLITE_OK
        sqlite3_finalize(stmt)
        error("could not bind parameter: $(sqlite3_errstr(err))")
    end
end

function sqlite3_bind_double(stmt, i, val)
    #=
     Bind a Float64 to a parameter.
    =#
    err = ccall(
        (:sqlite3_bind_double, SQLITELIB),
        Cint,
        (Ptr{Void}, Cint, Cdouble),
        stmt,
        i,
        val
    )
    if err != SQLITE_OK
        sqlite3_finalize(stmt)
        error("could not bind parameter: $(sqlite3_errstr(err))")
    end
end

function sqlite3_bind_text(stmt, i, val)
    #=
     Bind a String to a parameter.
    =#
    err = ccall(
        (:sqlite3_bind_text, SQLITELIB),
        Cint,
        (Ptr{Void}, Cint, Ptr{Uint8}, Cint, Ptr{Void}),
        stmt,
        i,
        val,
        sizeof(val)+1,
        -1  # SQLITE_TRANSIENT
    )
    if err != SQLITE_OK
        sqlite3_finalize(stmt)
        error("could not bind parameter: $(sqlite3_errstr(err))")
    end
end

function sqlite3_bind_blob(stmt, i, val, nbytes)
    #=
     Bind a Ptr{Void} to an argument.
    =#
    err = ccall(
        (:sqlite3_bind_blob, SQLITELIB),
        Cint,
        (Ptr{Void}, Cint, Ptr{Void}, Cint, Ptr{Void}),
        stmt,
        i,
        val,
        nbytes,
        -1  # SQLITE_TRANSIENT
    )
    if err != SQLITE_OK
        sqlite3_finalize(stmt)
        error("could not bind parameter: $(sqlite3_errstr(err))")
    end
end

function sqlite3_finalize(stmt)
    #=
     Free memory associated with the statement pointer.
    =#
    err = ccall(
        (:sqlite3_finalize, SQLITELIB),
        Cint,
        (Ptr{Void},),
        stmt
    )
    if err != SQLITE_OK
        warn("could not finalise statement: $(sqlite3_errstr(err))")
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
