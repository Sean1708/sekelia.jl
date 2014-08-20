using sekelia
using Base.Test

# test sekelia.utils.fixfilename()
@test sekelia.utils.fixfilename(nothing) == ":memory:"
@test sekelia.utils.fixfilename("") == ""
@test sekelia.utils.fixfilename(":yo") == "./:yo"
@test sekelia.utils.fixfilename("he") == "he"
@test sekelia.utils.fixfilename("/he") == "/he"
