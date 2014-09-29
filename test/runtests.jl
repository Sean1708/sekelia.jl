using sekelia
using Base.Test

# test sekelia.utils.fixfilename()
@test sekelia.utils.fixfilename(sekelia.MEMDB) == ":memory:"
@test sekelia.utils.fixfilename(sekelia.DISKDB) == ""
@test sekelia.utils.fixfilename(":yo") == "./:yo"
@test sekelia.utils.fixfilename("he") == "he"
@test sekelia.utils.fixfilename("/he") == "/he"

# test sekelia.utils.ismult()
@test sekelia.utils.ismult("INSERT INTO Students VALUES ('Robert');") == false
@test sekelia.utils.ismult("INSERT INTO Students VALUES ('Robert;')") == false
@test sekelia.utils.ismult("INSERT INTO Students VALUES ('Robert'); DROP TABLE Students;--')") == true

# test that a simple set of commands run correctly
db = sekelia.connect()
@test db.name == ":memory:"

sekelia.transaction(db) do
    sekelia.execute(
        db,
        """CREATE TABLE testtable (
            testcol TEXT,
            num INTEGER,
            fl REAL,
            bl BLOB
        );"""
    )
end

sekelia.transaction(db)
sekelia.execute(
    db,
    """INSERT INTO testtable VALUES (
        'First row.',
        1,
        1.1,
        X'010101'
    );"""
)
sekelia.commit(db)

sekelia.transaction(db, "sp")
sekelia.execute(
    db,
    """INSERT INTO testtable VALUES (
        'Second row.',
        2,
        2.2,
        NULL
    )"""
)
sekelia.commit(db, "sp")

sekelia.execute(
    db,
    """INSERT INTO testtable VALUES (?4, ?3, ?2, ?1)""",
    (Uint8[3, 3, 3], 3.3, 3, "Third row.")
)

sekelia.execute(
    db,
    """INSERT INTO testtable VALUES (:a, @b, \$c, :d)""",
    ["a" => "Fourth row.", "b" => 4, "c" => 4.4, "d" => Uint8[4, 4, 4]]
)

sekelia.execute(
    db,
    """INSERT INTO testtable VALUES (:a, :b, :c, :d)""",
    [:a => "Fifth row.", :b => 5, :c => 5.5, :d => Uint8[5, 5, 5]]
)

@test_throws Exception sekelia.execute(db, "SELECT * FROM testtable; VACUUM;")

@test_throws Exception transaction(db) do
    sekelia.execute(
        db,
        """INSERT INTO testtable VALUES('No.', 0, 0, NULL)"""
    )
    error()
end

res = sekelia.execute(db, "SELECT * FROM testtable"; header=true, types=true)
@test consume(res) == ("testcol", "num", "fl", "bl")
@test consume(res) <: (String, Union(Int32, Int64), Float64, Vector{Uint8})
@test consume(res) == ("First row.", 1, 1.1, Uint8[1, 1, 1])
@test consume(res) == ("Second row.", 2, 2.2, nothing)
@test consume(res) == ("Third row.", 3, 3.3, Uint8[3, 3, 3])
@test consume(res) == ("Fourth row.", 4, 4.4, Uint8[4, 4, 4])
@test consume(res) == ("Fifth row.", 5, 5.5, Uint8[5, 5, 5])
# finalize statement
@test consume(res) == nothing

# travis has an old version of the SQLite library
ccall(
    (:sqlite3_close, sekelia.api.SQLITELIB),
    Cint,
    (Ptr{Void},),
    db.handle
)
