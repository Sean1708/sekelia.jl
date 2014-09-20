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
        colnum INTEGER
    ); INSERT INTO testtable VALUES ("This should not be inserted.", 0)"""
)
sekelia.execute(db, """INSERT INTO testtable VALUES ("First row.", 1)""")
sekelia.execute(db, """INSERT INTO testtable VALUES ("Second row.", 2)""")
sekelia.execute(db, """INSERT INTO testtable VALUES ("Third row.", 3)""")

res = sekelia.execute(db, "SELECT * FROM testtable"; header=true)
@test consume(res) == ("testcol", "colnum")
@test consume(res) == ("First row.", 1)
@test consume(res) == ("Second row.", 2)
@test consume(res) == ("Third row.", 3)
consume(res)

sekelia.close(db)
