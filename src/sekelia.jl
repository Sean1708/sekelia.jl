module sekelia


export SPECIALDB, connectdb, close, execute

include("types.jl")
include("constants.jl")

module wrapper
include("wrapper.jl")
end

module utils
include("utils.jl")
end


function connect(file=SPECIALDB.memory)
    #=
     Connect to and return the specified SQLite database.

     If the file is SPECIALDB.memory a temporary in-memory database will be
     created. If the file is SPECIALDB.disk a temporary on-disk database will
     be created.
    =#
    file = utils.fixfilename(file)

    handle_ptr = Array(Ptr{Void}, 1)
    err = wrapper.sqlite3_open(file, handle_ptr)
    handle = handle_ptr[1]
    if err != SQLITE_OK
        error("unable to open $(file): $(wrapper.sqlite3_errstr(err))")
    else
        return SQLiteDB(file, handle)
    end
end
# avoid name clashes with predefined connect
connectdb = connect

function close(db::SQLiteDB)
    #=
     Close the database connection and cause the handle to be unusable.
    =#
    err = wrapper.sqlite3_close_v2(db.handle)
    if err != SQLITE_OK
        warn("error closing $(db.name): $(wrapper.sqlite3_errstr(err))")
    end
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

    prepstmt_ptr = Array(Ptr{Void}, 1)
    err = wrapper.sqlite3_prepare_v2(db.handle, stmt, prepstmt_ptr, [C_NULL])
    prepstmt = prepstmt_ptr[1]
    if err != SQLITE_OK
        error("could not execute statement: $(wrapper.sqlite3_errstr(err))")
    end

    err = wrapper.sqlite3_step(prepstmt)
    if err != SQLITE_DONE
        wrapper.sqlite3_finalize(prepstmt)
        error("error executing statment: $(wrapper.sqlite3_errstr(err))")
    end

    err = wrapper.sqlite3_finalize(prepstmt)
    if err != SQLITE_OK
        warn("possible error executing: $(wrapper.sqlite3_errstr(err))")
    end
end


end  # module
