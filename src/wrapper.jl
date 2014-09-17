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
     Retrieve the value from column col in the current row coverted to int.
    =#
    # sqlite is 0-indexed, julia ain't
    col -= 1
    return int(
        ccall(
            (:sqlite3_column_int, SQLITELIB),
            Cint,
            (Ptr{Void}, Cint),
            stmt,
            col
        )
    )
end

function sqlite3_column_text(stmt, col)
    #=
     Retrieve the value from column col in the current row coverted to char*.
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
