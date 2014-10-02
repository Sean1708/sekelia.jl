function regex(context, nargs, values)
    rgx = Regex(sqlvalue(values, 1))
    str = sqlvalue(values, 2)

    if ismatch(rgx, str)
        sqlreturn(context, 1)
    else
        sqlreturn(context, 0)
    end

    nothing
end
