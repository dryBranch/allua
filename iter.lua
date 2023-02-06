local iter_meta_index = {__type = "iterable"}
local lib = iter_meta_index
-- ===============================核心=================================
-- =============================基本函数===============================
-- 给函数的简单包装（惰性）
-- [unstable]
local function iter_new( iter_func )
    local this = { __iter_state = "ready" }
    this.this = this
    local it_fn = function (  )
        -- 最后一次会返回 true, nil
        local status, v = pcall(iter_func)
        if v == nil then 
            this.__iter_state = "consumed"
        end
        if status then
            return v
        else
            return nil
        end
    end

    local t = type(iter_func)
    if t == "function" then
        return setmetatable(this, {__call = it_fn, __index = iter_meta_index})
    else
        return nil, "#1 is not a iterable function"
    end
end

-- 用于返回迭代器的多返回值
local function go_ahead( iter )
    while true do
        local r = {iter()}
        if r[1] then
            coroutine.yield( table.unpack(r) )
        else
            break
        end
    end
end



-- 得到顺序迭代序列和可迭代函数的迭代器（惰性）
function chain( ... )
    local this = { __iter_state = "ready" }
    this.this = this
    local iters = {...}
    local chain_fn = coroutine.wrap( function (  )
        for n, iter in ipairs(iters) do
            local t = type(iter)
            -- 判断迭代方式
            if t == "table" then
                -- 表有两种迭代方式
                if type(iter.__next) == "function" then
                    -- 如果这个表有__next迭代函数则使用这个函数迭代
                    go_ahead(iter.__next)
                elseif iter.__type == "iterable" then
                    -- chain(...)生成的会使用这个迭代
                    if iter:ready() then
                        go_ahead(iter)
                    else
                        error(string.format("#%d: %s is comsumed", n, t))
                    end
                else
                    -- 没有则按照普通序列迭代
                    for i, item in ipairs(iter) do
                        coroutine.yield( item )
                    end
                end
            elseif t == "function" then
                go_ahead(iter)
            else
                error(string.format("#%d: %s is not iterable", n, t))
            end
        end
        this.__iter_state = "comsumed"
        this.this = nil
    end )
    -- 返回一个迭代器类型
    return setmetatable(this, {__call = chain_fn, __index = iter_meta_index})
end

-- 判断迭代器是否被消耗
function lib.ready( iter )
    return iter.__iter_state == "ready"
end

-- =============================基本函数===============================

-- =============================惰性函数===============================


-- 返回对可迭代类型执行函数的迭代器（惰性）
-- fn(it) -> ait
function lib.map( iter, fn )
    return chain(coroutine.wrap( function (  )
        for item in iter do
            coroutine.yield( fn(item) )
        end
    end ))
end

-- 返回过滤后的迭代器（惰性）
-- fn(it) -> bool
function lib.filter( iter, fn )
    return chain(coroutine.wrap( function (  )
        for item in iter do
            if fn(item) then
                coroutine.yield( item )
            end
        end
    end ))
end

-- 返回组合迭代器（惰性）
function lib.zip( iter_a, iter_b )
    return chain(coroutine.wrap( function (  )
        while true do
            local ia, ib = iter_a(), iter_b()
            if ia and ib then
                coroutine.yield( ia, ib )
            else
                iter_a.__iter_state = "comsumed"
                iter_b.__iter_state = "comsumed"
                break
            end
        end
    end ))
end

-- 返回带从1开始序号的迭代器（惰性）
function lib.enumerate( iter )
    return chain(coroutine.wrap( function (  )
        -- local n = 1
        -- for item in iter do
        --     coroutine.yield( n, item )
        --     n = n + 1
        -- end
        
        -- 多返回实现
        local n = 1
        while true do
            local r = {iter()}
            if r[1] then
                coroutine.yield( n, table.unpack(r) )
                n = n + 1
            else
                break
            end
        end
    end ))
end



-- =============================惰性函数===============================

-- =============================消耗函数===============================
-- 消耗函数如果已经被消耗了，那么返回值为nil, err，不再抛出错误
--[[
fold 折叠
1. 给一个初始值acc作为迭代的中间值和结果
2. 给一个操作函数fn(acc, x) -> r
3. 迭代至结束

# 过程图
e   acc	x	result
    0		
1	0	1	1
2	1	2	3
3	3	3	6 

# 例子
local r = range(1, 101):fold(0, function(acc, x) return acc + x end)
assert(r == 5050)
]]
function lib.fold( iter, acc, fn )
    if iter:ready() then
        for item in iter do
            acc = fn(acc, item)
        end
        return acc
    elseif acc then
        return acc
    else
        return nil, "This iterator is comsumed"
    end
end

-- 将第一个迭代结果作为初值进行fold
function lib.reduce( iter, fn )
    if iter:ready() then
        local acc = iter()
        return iter:fold(acc, fn)
    else
        return nil, "This iterator is comsumed"
    end
end

-- 只适用于number的求和（消耗）
function lib.sum( iter )
    return iter:reduce(function(acc, x) return acc + x end)
end

function lib.max( iter )
    return iter:reduce(function(acc, x) return acc > x and acc or x end)
end

-- 将迭代器转为序列（消耗）
function lib.to_vec( iter )
    if iter:ready() then
        local t = {}
        local n = 0
        for item in iter do
            n = n + 1
            t[n] = item
        end
        return t
    else
        return nil, "This iterator is comsumed"
    end
end

-- 计算迭代器迭代次数（消耗）
function lib.count( iter )
    if iter:ready() then
        local n = 0
        for _ in iter do
            n = n + 1
        end
        return n
    else
        return nil, "This iterator is comsumed"
    end
end

-- 对迭代器中的每个元素执行操作（消耗）
-- fn(it)
function lib.foreach( iter, fn )
    if iter:ready() then
        for item in iter do
            fn(item)
        end
    else
        return nil, "This iterator is comsumed"
    end
end

-- 消耗迭代器（消耗）
function lib.comsume( iter )
    if iter:ready() then
        for _ in iter do end
    else
        return nil, "This iterator is comsumed"
    end
end
-- =============================消耗函数===============================
-- ===============================核心=================================

-- ============================常用迭代器===============================
-- 范围迭代器
-- range(stop)
-- range(start, stop)
-- range(start, stop, step)
-- 支持负数
function range( stop, start, step )
    start, stop = start and stop or 0, start or stop
    step = step or 1
    if math.type(start) ~= 'integer' then error("#1 is not a integer") end
    if math.type(stop) ~= 'integer' then error("#2 is not a integer") end
    if math.type(step) ~= 'integer' then error("#3 is not a integer") end
    
    local co_fn = coroutine.wrap( function (  )
        for i = start, stop-( step > 0 and 1 or -1 ), step do
            coroutine.yield(i)
        end
    end )
    -- return iter_new(co_fn)
    return chain(co_fn)
end


-- ============================常用迭代器===============================