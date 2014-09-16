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

function rowiter(prepstmt)
    #=
     Iterate through rows returned by prepstmt.

     If used by calling consume(), it must be called one more time than the
     number of rows returned so that memory is properly freed.
    =#
    ncol = wrapper.sqlite3_column_count(prepstmt)
    status = wrapper.SQLITE_ROW

    while status != wrapper.SQLITE_DONE
        produce(ntuple(ncol, i -> retrieverow(prepstmt, i)))
        status = wrapper.sqlite3_step(prepstmt)
    end

    wrapper.sqlite3_finalize(prepstmt)
end
