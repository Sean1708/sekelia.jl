function registerfunc(db, name, nargs, func, step, final, isdeterm)
    #= 
     Create a function in the database connection db.
    =#
    if func != nothing
        msg = "step and final can not be defined for scalar functions"
        @assert (step == final == nothing) msg
    else
        msg = "both step and final must be defined for aggregate functions"
        @assert (step != nothing && final != nothing) msg
        msg = "func must not be defined for aggregate functions"
        @assert (func == nothing) msg
    end

    cfunc = func == nothing ? C_NULL : cfunction(
        func, Nothing, (Ptr{Void}, Cint, Ptr{Ptr{Void}})
    )
    cstep = step == nothing ? C_NULL : cfunction(
        step, Nothing, (Ptr{Void}, Cint, Ptr{Ptr{Void}})
    )
    cfinal = final == nothing ? C_NULL : cfunction(
        step, Nothing, (Ptr{Void}, Cint, Ptr{Ptr{Void}})
    )

    enc = api.SQLITE_UTF8
    enc = isdeterm ? enc | api.SQLITE_DETERMINISTIC : enc

    api.sqlite3_create_function_v2(
        db.handle, name, nargs, enc, C_NULL, cfunc, cstep, cfinal, C_NULL
    )
end

# scalar functions
function registerfunc(db::Database, nargs::Integer, func::Function,
                      isdeterm::Bool=true; name="")
    name = isempty(name) ? string(func) : name
    registerfunc(db, name, nargs, func, nothing, nothing, isdeterm)
end

# aggregate functions
function registerfunc(db::Database, nargs::Integer, step::Function,
                      final::Function, isdeterm::Bool=true; name="")
    name = isempty(name) ? string(step) : name
    registerfunc(db, name, nargs, nothing, step, final, isdeterm)
end


function sqlvalue(values, i)
    temp_val_ptr = unsafe_load(values, i)
    valuetype = api.sqlite3_value_type(temp_val_ptr)

    if valuetype == api.SQLITE_INTEGER
        if WORD_SIZE == 64
            return api.sqlite3_value_int64(temp_val_ptr)
        else
            return api.sqlite3_value_int(temp_val_ptr)
        end
    elseif valuetype == api.SQLITE_FLOAT
        return api.sqlite3_value_double(temp_val_ptr)
    elseif valuetype == api.SQLITE_TEXT
        return api.sqlite3_value_text(temp_val_ptr)
    elseif valuetype == api.SQLITE_BLOB
        return api.sqlite3_value_blob(temp_val_ptr)
    else
        return nothing
    end
end

# returns mapping directly to sqlite datatypes
sqlreturn(context, ::Nothing) = api.sqlite3_result_null(context)
sqlreturn(context, val::Int32) = api.sqlite3_result_int(context, val)
sqlreturn(context, val::Int64) = api.sqlite3_result_int64(context, val)
sqlreturn(context, val::Float64) = api.sqlite3_result_double(context, val)
sqlreturn(context, val::String) = api.sqlite3_result_text(context, val)
sqlreturn(context, val::Ptr{Void}, n) = api.sqlite3_result_blob(context, val, n)

# returns mapping to other types
function sqlreturn(context, val::Integer)
    if WORD_SIZE == 64
        sqlreturn(context, int64(val))
    else
        sqlreturn(context, int32(val))
    end
end
sqlreturn(context, val::FloatingPoint) = sqlreturn(context, float64(val))
sqlreturn(context, val::Char) = sqlreturn(context, string(val))
sqlreturn(context, val::Symbol) = sqlreturn(context, string(val))
function sqlreturn{T}(context, val::Array{T})
    flat = reshape(val, length(val))
    nbytes = sizeof(flat)
    sqlreturn(context, convert(Ptr{Void}, flat), nbytes)
end

sqlerror(context, msg) = api.sqlite3_result_error(context, msg)

macro sqlfunc(args...)
    #=
     Don't ask. Just... please don't ask.

     Also, this definitely would not be possible without rennis250's getCFun
     macro.
    =#
    nothing
end
