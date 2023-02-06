function test( f, name )
    local r, info = pcall(f)
    if r then
        print(name .. "\t: pass")
    else
        print(name .. "\t: fail")
        print(info)
    end
end

function cmp( a, b )
    local ta, tb = type(a), type(b)
    local fmt = string.format
    assert(ta == tb, fmt("type not eq: %s is not %s, %s ~= %s", ta, tb, tostring(a), tostring(b)))
    if ta == "table" then
        local l1, l2 = #a, #b
        assert(l1 == l2, fmt("table len not eq: %d ~= %d, %s ~= %s", l1, l2, tostring(a[i]), tostring(b[i])))
        for i = 1, l1 do
            assert(a[i] == b[i], fmt("%s ~= %s", tostring(a[i]), tostring(b[i])))
        end
    else
        assert(a == b, fmt("%s ~= %s", tostring(a), tostring(b)))
    end
end