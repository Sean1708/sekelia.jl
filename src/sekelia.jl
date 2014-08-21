module sekelia

module wrapper
include("wrapper.jl")
end

module utils
include("utils.jl")
end


type SQLiteDB
    name::String
    handle::Ptr{Void}
end

immutable SpecialDB
    name::String
end
utils.fixfilename(name::SpecialDB) = name.name

immutable SpecialDBEnum
    memory::SpecialDB
    disk::SpecialDB

    SpecialDBEnum() = new(
        SpecialDB(":memory:"),
        SpecialDB("")
    )
end
const SPECIALDB = SpecialDBEnum()


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

end  # module
