const SPECIALDB = SpecialDBEnum()
const SQLITELIB = find_library(["libsqlite3"], [get(ENV, "SEKELIA_SQLITE", [])])


const SQLITE_OK = 0
