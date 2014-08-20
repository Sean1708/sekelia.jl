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

    SpecialDBEnum() = new(SpecialDB(":memory:"), SpecialDB(""))
end
const specialdbs = SpecialDBEnum()


function connect(file=specialdbs.memory)
    #=
     Connect to and return the specified SQLite database.

     If no filename is given a temporary database will be created in memory. If
     the filename is given as an empty string a temporary database will be
     created on disk.
    =#
    file = utils.fixfilename(file)
    handle_ptr = Array(Ptr{Void},1)

    err = wrapper.sqlite3_open(file, handle_ptr)
    handle = handle_ptr[1]

    if err != 0
        error("can't open $(file): $(wrapper.sqlite3_errmsg(handle))")
    else
        return SQLiteDB(file, handle)
    end
end

end  # module
