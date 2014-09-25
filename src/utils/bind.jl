# bind methods mapping directly to sqlite datatypes
bind(stmt, i, ::Nothing) = api.sqlite3_bind_null(stmt, i)
bind(stmt, i, val::Int32) = api.sqlite3_bind_int(stmt, i, val)
bind(stmt, i, val::Int64) = api.sqlite3_bind_int64(stmt, i, val)
bind(stmt, i, val::Float64) = api.sqlite3_bind_double(stmt, i, val)
bind(stmt, i, val::String) = api.sqlite3_bind_text(stmt, i, val)
bind(stmt, i, val::Ptr{Void}, n) = api.sqlite3_bind_blob(stmt, i, val, n)

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
    nparams = api.sqlite3_bind_parameter_count(stmt)
    nvalues = length(values)
    if nparams != nvalues
        api.sqlite3_finalize(stmt)
        error("$(nvalues) values supplied for $(nparams) parameters")
    else
        for i in 1:nparams
            bind(stmt, i, values[i])
        end
    end
end

