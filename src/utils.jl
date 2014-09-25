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
fixfilename(name::SpecialDB) = name.specifier

function ismult(stmt)
    #=
     Attempt to determine if stmt contains multiple SQLite statements.
    =#
    # quotes denoted by ', " or `
    quotequote = false
    quotemarks = ('\'', '"', '`')
    # quotes denoted by []
    bracequote = false
    # doesn't matter what the last character is as it can't start a new stmt
    for c in stmt[1:end-1]
        if c in quotemarks && !bracequote
            quotequote = !quotequote
        elseif c == '[' && !quotequote
            bracequote = true
        elseif c == ']' && bracequote
            bracequote = false
        elseif quotequote || bracequote
            # characters inside quotes can't end statements
            continue
        elseif c == ';'
            # if an unquoted ';' was found return true
            return true
        end
    end

    # if an unquoted ; was not found return false
    return false
end

