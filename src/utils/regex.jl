function regex(context, nargs, values)
    rgx_val = unsafe_load(values, 1)
    rgx = api.sqlite3_value_text(rgx_val)

    str_val = unsafe_load(values, 2)
    str = api.sqlite3_value_text(str_val)

    r = Regex(rgx)
    if ismatch(r, str)
        api.sqlite3_result_int(context, 1)
    else
        api.sqlite3_result_int(context, 0)
    end

    nothing
end
