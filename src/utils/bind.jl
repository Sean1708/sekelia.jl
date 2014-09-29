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
bind(stmt, i, val::Char) = bind(stmt, i, string(val))
bind(stmt, i, val::Symbol) = bind(stmt, i, string(val))
function bind{T}(stmt, i, val::Array{T})
    flat = reshape(val, length(val))
    nbytes = sizeof(flat)
    bind(stmt, i, convert(Ptr{Void}, flat), nbytes)
end

bindwrapper(stmt, i, values::(Any...,)) = bind(stmt, i, values[i])
#= CAN THIS BE DONE IN A MORE ELEGANT WAY? =#
function bindwrapper{V}(stmt, i, values::Dict{Any, V})
    name = api.sqlite3_bind_parameter_name(stmt, i)
    name == "" && error("nameless parameters should be passed as a tuple")
    #= CAN THIS BE DONE IN A MORE ELEGANT WAY? =#
    value = get(values, name) do
        get(values, symbol(name))
    end
    bind(stmt, i, value)
end
function bindwrapper{S <: String, V}(stmt, i, values::Dict{S, V})
    name = api.sqlite3_bind_parameter_name(stmt, i)
    name == "" && error("nameless parameters should be passed as a tuple")
    bind(stmt, i, values[name])
end
function bindwrapper{V}(stmt, i, values::Dict{Symbol, V})
    name = api.sqlite3_bind_parameter_name(stmt, i)
    name =="" && error("nameless parameters should be passed as a tuple")
    bind(stmt, i, values[symbol(name)])
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
            bindwrapper(stmt, i, values)
        end
    end
end

