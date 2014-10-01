function regex(context, nargs, values)
    if nargs != 2
        sqlerror(context, "incorrect number of arguments")
    end

    rgx = Regex(sqlvalue(values, 1))
    str = sqlvalue(values, 2)

    if ismatch(rgx, str)
        sqlreturn(context, 1)
    else
        sqlreturn(context, 0)
    end

    nothing
end
