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
