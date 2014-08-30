using ..SpecialDB


function fixfilename(name)
    #=
     Return a safe filename.

     Filenames beginning with ':' may cause issues with future versions of
     sqlite so prepend these with "./".
    =#
    if beginswith(name, ':')
        return "./" * name
    else
        return name
    end
end
# change name to something else
fixfilename(name::SpecialDB) = name.name

function ismult(stmt)
    #=
     Attempt to determine if stmt contains multiple SQLite statements.
    =#
    return rsearchindex(stmt, ";", endof(stmt)-1) > 0
end
