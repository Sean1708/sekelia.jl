function retrieverow(stmt, col)
    #=
     Retrieve the i-th value from the current row.
    =#
    coltype = api.sqlite3_column_type(stmt, col)

    if coltype == api.SQLITE_INTEGER
        if WORD_SIZE == 64
            return api.sqlite3_column_int64(stmt, col)
        else
            return api.sqlite3_column_int(stmt, col)
        end
    elseif coltype == api.SQLITE_FLOAT
        return api.sqlite3_column_double(stmt, col)
    elseif coltype == api.SQLITE_TEXT
        return api.sqlite3_column_text(stmt, col)
    elseif coltype == api.SQLITE_BLOB
        return api.sqlite3_column_blob(stmt, col)
    elseif coltype == api.SQLITE_NULL
        return nothing
    else
        error("unknown datatype code: $(coltype)")
    end
end

function retrievecolname(stmt, col)
    #=
     Retrieve the name of the i-th column.
    =#
    return api.sqlite3_column_name(stmt, col)
end

function retrievecoltype(stmt, col)
    #=
     Retrieve the concrete julia type of the i-th column.
    =#
    coltype = api.sqlite3_column_type(stmt, col)

    if coltype == api.SQLITE_INTEGER
        # Int is an alias to the correct concrete type
        return Int
    elseif coltype == api.SQLITE_FLOAT
        # standard floats are 64-bit
        return Float64
    elseif coltype == api.SQLITE_TEXT
        return typeof("")
    elseif coltype == api.SQLITE_BLOB
        # blobs are treated as bytearrays
        return Array{Uint8, 1}
    elseif coltype == api.SQLITE_NULL
        # Null is nothing
        return Nothing
    else
        api.sqlite3_finalize(stmt)
        error("unknown datatype code: $(coltype)")
    end
end

function rowiter(stmt, header, types)
    #=
     Iterate through rows returned by stmt.

     If used by calling consume(), it must be called one more time than the
     number of rows returned so that memory is properly freed.
    =#
    ncol = api.sqlite3_column_count(stmt)
    status = api.SQLITE_ROW

    header && produce(ntuple(ncol, i -> retrievecolname(stmt, i)))
    types && produce(ntuple(ncol, i -> retrievecoltype(stmt, i)))

    while status != api.SQLITE_DONE
        produce(ntuple(ncol, i -> retrieverow(stmt, i)))
        status = api.sqlite3_step(stmt)
    end

    api.sqlite3_finalize(stmt)
end

