type SQLiteDB
    name::String
    handle::Ptr{Void}
    # open::Bool if operating on closed dbs causes issues
end

immutable SpecialDB
    name::String
end

immutable SpecialDBEnum
    memory::SpecialDB
    disk::SpecialDB

    SpecialDBEnum() = new(
        SpecialDB(":memory:"),
        SpecialDB("")
    )
end
