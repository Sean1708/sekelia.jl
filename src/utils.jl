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
    # doesn't matter what the last character is as it can't start a new stmt
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

function retrieverow(stmt, col)
    #=
     Retrieve the i-th value from the current row.
    =#
    coltype = wrapper.sqlite3_column_type(stmt, col)

    if coltype == wrapper.SQLITE_INTEGER
        if WORD_SIZE == 64
            return wrapper.sqlite3_column_int64(stmt, col)
        else
            return wrapper.sqlite3_column_int(stmt, col)
        end
    elseif coltype == wrapper.SQLITE_FLOAT
        return wrapper.sqlite3_column_double(stmt, col)
    elseif coltype == wrapper.SQLITE_TEXT
        return wrapper.sqlite3_column_text(stmt, col)
    elseif coltype == wrapper.SQLITE_BLOB
        return wrapper.sqlite3_column_blob(stmt, col)
    elseif coltype == wrapper.SQLITE_NULL
        return nothing
    else
        error("unknown datatype code: $(coltype)")
    end
end

function retrievecolname(stmt, col)
    #=
     Retrieve the name of the i-th column.
    =#
    return wrapper.sqlite3_column_name(stmt, col)
end

function retrievecoltype(stmt, col)
    #=
     Retrieve the concrete julia type of the i-th column.
    =#
    coltype = wrapper.sqlite3_column_type(stmt, col)

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
        wrapper.sqlite3_finalize(stmt)
        error("unknown datatype code: $(coltype)")
    end
end

function rowiter(stmt, header, types)
    #=
     Iterate through rows returned by stmt.

     If used by calling consume(), it must be called one more time than the
     number of rows returned so that memory is properly freed.
    =#
    ncol = wrapper.sqlite3_column_count(stmt)
    status = wrapper.SQLITE_ROW

    header && produce(ntuple(ncol, i -> retrievecolname(stmt, i)))
    types && produce(ntuple(ncol, i -> retrievecoltype(stmt, i)))

    while status != wrapper.SQLITE_DONE
        produce(ntuple(ncol, i -> retrieverow(stmt, i)))
        status = wrapper.sqlite3_step(stmt)
    end

    wrapper.sqlite3_finalize(stmt)
end
  
# bind methods mapping directly to sqlite datatypes
bind(stmt, i, ::Nothing) = wrapper.sqlite3_bind_null(stmt, i)
bind(stmt, i, val::Int32) = wrapper.sqlite3_bind_int(stmt, i, val)
bind(stmt, i, val::Int64) = wrapper.sqlite3_bind_int64(stmt, i, val)
bind(stmt, i, val::Float64) = wrapper.sqlite3_bind_double(stmt, i, val)
bind(stmt, i, val::String) = wrapper.sqlite3_bind_text(stmt, i, val)
bind(stmt, i, val::Ptr{Void}, n) = wrapper.sqlite3_bind_blob(stmt, i, val, n)

# bind methods mapping to other bind methods
function bind(stmt, i, val::Integer)
    if WORD_SIZE == 64
        bind(stmt, i, int64(val))
    else
        bind(stmt, i, int32(val))
    end
end
bind(stmt, i, val::FloatingPoint) = bind(stmt, i, float64(val))
bind(stmt, i, val::Union(BigInt, BigFloat)) = bind(stmt, i, string(val))
function bind{T}(stmt, i, val::Array{T})
    flat = reshape(val, length(val))
    nbytes = sizeof(flat)
    bind(stmt, i, convert(Ptr{Void}, flat), nbytes)
end

function bindparameters(stmt, values)
    #=
     Bind the parameters in the tuple values to the variables in stmt.
    =#
    nparams = wrapper.sqlite3_bind_parameter_count(stmt)
    nvalues = length(values)
    if nparams != nvalues
        wrapper.sqlite3_finalize(stmt)
        error("$(nvalues) values supplied for $(nparams) parameters")
    else
        for i in 1:nparams
            bind(stmt, i, values[i])
        end
    end
end
