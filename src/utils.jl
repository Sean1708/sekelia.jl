function fixfilename(name)
    #=
     Return a safe filename or ":memory" as required.

     Filenames beginning with ':' may cause issues with future versions of
     sqlite so prepend these with "./". Also return ":memory" if name is none.
    =#
    if is(name, nothing)
        return ":memory"
    elseif beginswith(name, ':')
        return "./" * name
    else
        return name
    end
end
