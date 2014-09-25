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

# result codes can be hard-coded as sqlite specifies they will not change
const SQLITE_TRANSIENT = convert(Ptr{Void}, -1)
const SQLITE_STATIC = convert(Ptr{Void}, 0)
const SQLITE_OK = 0
const SQLITE_INTEGER = 1
const SQLITE_FLOAT = 2
const SQLITE_TEXT = 3
const SQLITE_BLOB = 4
const SQLITE_NULL = 5
const SQLITE_ROW = 100
const SQLITE_DONE = 101

