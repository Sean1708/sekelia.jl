using ..SpecialDB
using ..wrapper


function fixfilename(name)
    #=
     Return a safe filename.

     Filenames beginning with ':' may cause issues with future versions of
     sqlite so prepend these with "./".
    =#
    if beginswith(name, ':')
        return "./" * name
    else
        return name
    end
end
fixfilename(name::SpecialDB) = name.specifier

function ismult(stmt)
    #=
     Attempt to determine if stmt contains multiple SQLite statements.
    =#
    return rsearchindex(stmt, ";", endof(stmt)-1) > 0
end

function retrieverow(prepstmt, i)
    #=
     Retrieve the i-th value from the current row.
    =#
    # sqlite is 0 indexed, julia ain't
    col = i - 1
    coltype = wrapper.sqlite3_column_type(prepstmt, col)

    if coltype == wrapper.SQLITE_INTEGER
        return wrapper.sqlite3_column_int(prepstmt, col)
    elseif coltype == wrapper.SQLITE_FLOAT
        return wrapper.sqlite3_column_double(prepstmt, col)
    elseif coltype == wrapper.SQLITE_TEXT
        return wrapper.sqlite3_column_text(prepstmt, col)
    elseif coltype == wrapper.SQLITE_BLOB
        return wrapper.sqlite3_column_text(prepstmt, col)
    elseif coltype == wrapper.SQLITE_NULL
        return nothing
    else
        error("unknown datatype code: $(coltype)")
    end
end

function retrievecolname(prepstmt, i)
    #=
     Retrieve the name of the i-th column.
    =#
    col = i - 1
    return wrapper.sqlite3_column_name(prepstmt, col)
end

function retrievecoltype(prepstmt, i)
    #=
     Retrieve the concrete julia type of the i-th column.
    =#
    col = i - 1
    coltype = wrapper.sqlite3_column_type(prepstmt, col)

    if coltype == wrapper.SQLITE_INTEGER
        # Int is an alias to the correct concrete type
        return Int
    elseif coltype == wrapper.SQLITE_FLOAT
        # standard floats are 64-bit
        return Float64
    elseif coltype == wrapper.SQLITE_TEXT
        return typeof("")
    elseif coltype == wrapper.SQLITE_BLOB
        return typeof("")
    elseif coltype == wrapper.SQLITE_NULL
        return Nothing
    else
        error("unknown datatype code: $(coltype)")
    end
end

function rowiter(prepstmt, header, types)
    #=
     Iterate through rows returned by prepstmt.

     If used by calling consume(), it must be called one more time than the
     number of rows returned so that memory is properly freed.
    =#
    ncol = wrapper.sqlite3_column_count(prepstmt)
    status = wrapper.SQLITE_ROW

    if header
        produce(ntuple(ncol, i -> retrievecolname(prepstmt, i)))
    end
    if types
        produce(ntuple(ncol, i -> retrievecoltype(prepstmt, i)))
    end

    while status != wrapper.SQLITE_DONE
        produce(ntuple(ncol, i -> retrieverow(prepstmt, i)))
        status = wrapper.sqlite3_step(prepstmt)
    end

    wrapper.sqlite3_finalize(prepstmt)
end
