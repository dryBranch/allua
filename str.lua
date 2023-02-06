local str = {}

function str.ltrim( s )
    return s:match("^%s*(.*)")
end

function str.rtrim( s )
    return s:match("(.-)%s*$")
end

function str.trim( s )
    return s:match("^%s*(.-)%s*$")
end

function str.split( s, seperator )
    local all = {}
    local b = 1
    for p, n in function() return s:find(seperator, b, true) end do
        all[#all+1] = s:sub(b, p-1)
        b = n + 1
    end
    all[#all+1] = s:sub(b, -1)
    return all
end

function str.format( fmt, val_table )
    return (fmt:gsub("$([%w_]+)", function ( w )
        return val_table[w] or val_table[math.tointeger(w)]
    end))
end

return str