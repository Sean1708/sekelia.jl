module sekelia

# look for user's libsqlite3 and throw error if it could not be found
const SQLITELIB = begin
    local lib = find_library(
        ["libsqlite3"],
        [get(ENV, "SEKELIA_SQLITE", [])]
    )
    if lib == ""
        info("libsqlite3 could not be found")
        info("consider setting SEKELIA_SQLITE environment variable")
        error("SQLite3 library could not be loaded")
    else
        lib
    end
end

# wrapper around a string so that multiple dispatch can be used for
# util.fixfilename(). this is simpler than checkng for ":memory:" or ""
immutable SpecialDB
    specifier::String
end
immutable SpecialDBEnum
    memory::SpecialDB
    disk::SpecialDB

    SpecialDBEnum() = new(
        SpecialDB(":memory:"),
        SpecialDB("")
    )
end
const SPECIALDB = SpecialDBEnum()


module wrapper
include("wrapper.jl")
end

module utils
include("utils.jl")
end

export SPECIALDB, connectdb, close, execute


type SQLiteDB
    #=
     name : filename of the database
     handle : pointer associated with the database
    =#
    name::String
    handle::Ptr{Void}
end


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
# avoid name clashes with predefined connect
connectdb = connect

function close(db::SQLiteDB)
    #=
     Close the database connection and cause the handle to be unusable.
    =#
    wrapper.sqlite3_close_v2(db.handle)
end

function execute(db, stmt)
    #=
     Execute the given statement on the given db, returning results if any.

     Rows are returned as a task implementing the producer-consumer paradigm,
     i.e. the returned object can be itereated through in a for loop or each
     row can be retreived using the consume() method.

     Each row is returned as a tuple of values converted to the native
     representation using int(), float() or bytestring().

     execute() will only execute the first statement passed and will attempt to
     warn the user if multiple statements are passed.
    =#
    if utils.ismult(stmt)
        warn("only the first statement will be executed")
    end

    prepstmt = wrapper.sqlite3_prepare_v2(db.handle, stmt)
    status = wrapper.sqlite3_step(prepstmt)

    if status == wrapper.SQLITE_ROW
        return @task utils.rowiter(prepstmt)
    else
        wrapper.sqlite3_finalize(prepstmt)
    end
end


end  # module
