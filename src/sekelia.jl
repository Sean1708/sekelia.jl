module sekelia


export SPECIALDB, connectdb, close

include("types.jl")
include("constants.jl")

module wrapper
include("wrapper.jl")
end

module utils
include("utils.jl")
end
utils.fixfilename(name::SpecialDB) = name.name



# FUNCTIONS
function connect(file=SPECIALDB.memory)
    #=
     Connect to and return the specified SQLite database.

     If the file is SPECIALDB.memory a temporary in-memory database will be
     created. If the file is SPECIALDB.disk a temporary on-disk database will
     be created.
    =#
    file = utils.fixfilename(file)
    handle = wrapper.sqlite3_open(file)

    return SQLiteDB(file, handle)
end
connectdb = connect

function close(db::SQLiteDB)
    #=
     Close the database connection and cause the handle to be unusable.
    =#
    wrapper.sqlite3_close(db)
    db.name = ""
    db.handle = C_NULL
end

end  # module
