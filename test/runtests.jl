using sekelia
using Base.Test

# test sekelia.utils.fixfilename()
@test sekelia.utils.fixfilename(sekelia.SPECIALDB.memory) == ":memory:"
@test sekelia.utils.fixfilename(sekelia.SPECIALDB.disk) == ""
@test sekelia.utils.fixfilename(":yo") == "./:yo"
@test sekelia.utils.fixfilename("he") == "he"
@test sekelia.utils.fixfilename("/he") == "/he"

# test sekelia.utils.ismult()
@test sekelia.utils.ismult("INSERT INTO Students VALUES ('Robert');") == false
@test sekelia.utils.ismult("INSERT INTO Students VALUES ('Robert')") == false
@test sekelia.utils.ismult("INSERT INTO Students VALUES ('Robert'); DROP TABLE Students;--')") == false
