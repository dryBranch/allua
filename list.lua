local mt = {}
local method = {}
mt.__method = method
local lib = mt

function mt.__tostring( self )
    local r = {}
    local n = 1
    for _i, v in ipairs(self) do
        r[n] = tostring(v)
        n = n + 1
    end
    return "[" .. table.concat(r, ", ") .. "]"
end

function mt.__add( self, rl )
    local l = list{}
    l:extend(self)
    l:extend(rl)
    return l
end

-- 左闭右闭视图
function mt.__index( self, index )
    local t = type(index)
    if t == "string" then
        return lib.__method[index]
    elseif t == "table" then
        -- [unstable]
        local len = #index
        local view_copy = list{}
        if len == 2 then
            table.move(self, index[1], index[2], 1, view_copy)
        elseif len == 3 then
            -- table.move(self, index[1], index[2], 1, view)
            error("unsupport opetion: three params")
        end
        return view_copy
    end
end

function method.extend( self, t )
    table.move(t, 1, #t, #self + 1, self)
end

function method.push( self, v )
    self[#self + 1] = v
end

function method.pop( self )
    local v = self[#self]
    self[#self] = nil
    return v
end

function list( t )
    return setmetatable(t or {}, mt)
end