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
    # quotes denoted by ', " or `
    quotequote = false
    quotemarks = ('\'', '"', '`')
    # quotes denoted by []
    bracequote = false
    for c in stmt[1:end-1]
        if c in quotemarks && !bracequote
            quotequote = !quotequote
        elseif c == '[' && !quotequote
            bracequote = true
        elseif c == ']' && bracequote
            bracequote = false
        elseif quotequote || bracequote
            # characters inside quotes can't end statements
            continue
        elseif c == ';'
            # if an unquoted ';' was found return true
            return true
        end
    end

    # if an unquoted ; was not found return false
    return false
end

function retrieverow(prepstmt, col)
    #=
     Retrieve the i-th value from the current row.
    =#
    coltype = wrapper.sqlite3_column_type(prepstmt, col)

    if coltype == wrapper.SQLITE_INTEGER
        return wrapper.sqlite3_column_int(prepstmt, col)
    elseif coltype == wrapper.SQLITE_FLOAT
        return wrapper.sqlite3_column_double(prepstmt, col)
    elseif coltype == wrapper.SQLITE_TEXT
        return wrapper.sqlite3_column_text(prepstmt, col)
    elseif coltype == wrapper.SQLITE_BLOB
        return wrapper.sqlite3_column_blob(prepstmt, col)
    elseif coltype == wrapper.SQLITE_NULL
        return nothing
    else
        error("unknown datatype code: $(coltype)")
    end
end

function retrievecolname(prepstmt, col)
    #=
     Retrieve the name of the i-th column.
    =#
    return wrapper.sqlite3_column_name(prepstmt, col)
end

function retrievecoltype(prepstmt, col)
    #=
     Retrieve the concrete julia type of the i-th column.
    =#
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
        # blobs are treated as bytearrays
        return Array{Uint8, 1}
    elseif coltype == wrapper.SQLITE_NULL
        # Null is nothing
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

    header && produce(ntuple(ncol, i -> retrievecolname(prepstmt, i)))
    types && produce(ntuple(ncol, i -> retrievecoltype(prepstmt, i)))

    while status != wrapper.SQLITE_DONE
        produce(ntuple(ncol, i -> retrieverow(prepstmt, i)))
        status = wrapper.sqlite3_step(prepstmt)
    end

    wrapper.sqlite3_finalize(prepstmt)
end
