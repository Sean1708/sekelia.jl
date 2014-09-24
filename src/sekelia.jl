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


# bypass database name checking in utils.fixfilename()
immutable SpecialDB
    specifier::String
end
const MEMDB = SpecialDB(":memory:")
const DISKDB = SpecialDB("")


module wrapper
include("wrapper.jl")
end

module utils
include("utils.jl")
end

export MEMDB, DISKDB, connectdb, close, execute, transaction, commit, rollback


type SQLiteDB
    #=
     name : filename of the database
     handle : pointer associated with the database
    =#
    name::String
    handle::Ptr{Void}
end


function connect(file=MEMDB)
    #=
     Connect to and return the specified SQLite database.

     If the file is MEMDB a temporary in-memory database will be
     created. If the file is DISKDB a temporary on-disk database will
     be created.
    =#
    file = utils.fixfilename(file)
    handle = wrapper.sqlite3_open(file)
    return SQLiteDB(file, handle)
end
# avoid name clashes with predefined connect
connectdb = connect

# close databse, causing handle to become unusable
close(db::SQLiteDB) = wrapper.sqlite3_close_v2(db.handle)

function execute(db, stmt, values...; header=false, types=false)
    #=
     Execute the given statement on the given db, returning results if any.

     Rows are returned as a task implementing the producer-consumer paradigm,
     i.e. the returned object can be itereated through in a for loop or each
     row can be retreived using the consume() method.

     Each row is returned as a tuple of values converted to the native
     representation using int(), float() or bytestring().

     execute() will only execute the first statement passed and will raise an
     error if multiple statements are passed. This protects against statements
     incorrectly constructed using string interpolation.
    =#
    utils.ismult(stmt) && error("can't execute multiple statements")

    prepstmt = wrapper.sqlite3_prepare_v2(db.handle, stmt)
    utils.bindparameters(prepstmt, values)
    status = wrapper.sqlite3_step(prepstmt)

    if status == wrapper.SQLITE_ROW
        return @task utils.rowiter(prepstmt, header, types)
    else
        wrapper.sqlite3_finalize(prepstmt)
    end
end

function transaction(db, mode="DEFERRED")
    #=
     Begin a transaction in the spedified mode, default "DEFERRED".

     If mode is one of "", "DEFERRED", "IMMEDIATE" or "EXCLUSIVE" then a
     transaction of that (or the default) type is started. Otherwise a savepoint
     is created whose name is mode converted to String.
    =#
    if upper(mode) in ["", "DEFERRED", "IMMEDIATE", "EXCLUSIVE"]
        execute(db, "BEGIN $(mode) TRANSACTION;")
    else
        execute(db, "SAVEPOINT $(mode);")
    end
end

function transaction(f::Function, db)
    #=
     Execute the function f within a transaction.
    =#
    # generate a random name for the savepoint
    name = randstring(rand(10:50))
    transaction(db, name)
    try
        f()
    catch
        rollback(db, name)
        rethrow()
    finally
        # savepoints are not released on rollback
        commit(db, name)
    end
end

# commit a transaction or savepoint (if name is given)
commit(db) = execute(db, "COMMIT TRANSACTION;")
commit(db, name) = execute(db, "RELEASE SAVEPOINT $(name);")

# rollback transaction or savepoint (if name is given)
rollback(db) = execute(db, "ROLLBACK TRANSACTION;")
rollback(db, name) = execute(db, "ROLLBACK TRANSACTION TO SAVEPOINT $(name);")


end  # module
