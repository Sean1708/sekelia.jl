const SPECIALDB = SpecialDBEnum()
const SQLITELIB = begin
    local lib = find_library(
        ["libsqlite3"],
        [get(ENV, "SEKELIA_SQLITE", [])]
    )
    if lib == ""
        info("libsqlite3 could not be found.")
        info("consider setting SEKELIA_SQLITE environment variable.")
        error("SQLite3 library could not be loaded.")
    else
        lib
    end
end

const SQLITE_OK = 0
