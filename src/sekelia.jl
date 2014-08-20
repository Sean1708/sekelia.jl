module sekelia

module wrapper
include("wrapper.jl")
end

module utils
include("utils.jl")
end


type SQLiteDB
    filename::String
    handle::Ptr{Void}
end


function connect(filename=nothing)
    #=
     Connect to and return the specified SQLite database.

     If no filename is given a temporary database will be created in memory. If
     the filename is given as an empty string a temporary database will be
     created on disk.
    =#
    filename = utils.fixfilename(filename)
    handle_ptr = Array(Ptr{Void},1)

    err = wrapper.sqlite3_open(filename, handle_ptr)
    handle = handle_ptr[1]

    if err != 0
        error("can't open $(filename): $(wrapper.sqlite3_errmsg(handle))")
    else
        # return SQLiteDB(filename, handle)
        println(filename)
        println(handle)
    end
end

end  # module
