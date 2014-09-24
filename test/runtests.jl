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

sekelia.execute(
    db,
    """CREATE TABLE testtable (
        testcol TEXT,
        num INTEGER,
        fl REAL,
        bl BLOB
    );"""
)
sekelia.execute(
    db,
    """INSERT INTO testtable VALUES (
        'First row.',
        1,
        1.1,
        X'010101'
    );"""
)
sekelia.execute(
    db,
    """INSERT INTO testtable VALUES (
        'Second row.',
        2,
        2.2,
        NULL
    )"""
)
sekelia.execute(
    db,
    """INSERT INTO testtable VALUES (?, ?, ?, ?)""",
    "Third row.",
    3,
    3.3,
    Uint8[3, 3, 3]
)
@test_throws Exception sekelia.execute(db, "SELECT * FROM testtable; VACUUM;")

res = sekelia.execute(db, "SELECT * FROM testtable"; header=true, types=true)
@test consume(res) == ("testcol", "num", "fl", "bl")
@test consume(res) <: (String, Union(Int32, Int64), Float64, Vector{Uint8})
@test consume(res) == ("First row.", 1, 1.1, Uint8[1,1,1])
@test consume(res) == ("Second row.", 2, 2.2, nothing)
@test consume(res) == ("Third row.", 3, 3.3, Uint8[3,3,3])
# finalize statement
consume(res)

sekelia.close(db)
