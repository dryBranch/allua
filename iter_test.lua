assert(require("iter"))
assert(require("test"))

a = {1, 2, 3}
b = {"a", "b", "c"}
c = {19, 18, 17, __next = coroutine.wrap( function (  )
    local this = c
    for i = #this, 1, -1 do
        coroutine.yield( this[i] )
    end
end )} -- {17, 18, 19}
d = range(1, 9, 2) -- {1, 3, 5, 7}

-- ====================basic===================
function basic_test(  )
    local iter = chain(chain(a, b, c, d), {"extra"})
    local exp = {
        1, 2, 3,
        "a", "b", "c",
        17, 18, 19,
        1, 3, 5, 7,
        "extra"
    }
    assert(iter.__type == "iterable")
    assert(iter.__iter_state == "ready")
    local n = 0
    for item in iter do
        n = n + 1
        cmp(item, exp[n])
    end
    assert(iter.__type == "iterable")
    assert(iter.__iter_state == "comsumed")
end

test(basic_test, "basic test")

-- ===================extra=======================

function extra_test(  )
    assert(chain(a, b):count())
    local exp = {
        1, 2, 3,
        "a", "b", "c"
    }
    cmp(chain(a, b):to_vec(), exp)

    local r = range(10)
    local cnt = 0
    r:map(function(it) return it + 10 end)
        :filter(function(it) return it & 1 == 0 end)
        :foreach(function(it) cnt = cnt + it end)

    assert(cnt == 70)
    assert(r:count() == nil)

    cnt = {num = 0, str = 0}
    chain(a, b):foreach(function ( it )
        local t = type(it)
        if t == "number" then
            cnt.num = cnt.num + 1
        elseif t == "string" then
            cnt.str = cnt.str + 1
        end
    end)
    assert(cnt.num == 3)
    assert(cnt.str == 3)
end

test(extra_test, "extra test")

function more_test(  )
    for a, b in range(1, 10):zip(range(9, 0, -1)) do
        assert(a + b == 10)
    end

    for i, a, b in range(10):zip(range(5, 0, -1)):enumerate() do
        assert(i and a and b)
    end

    -- 1 + 4 + 9 + 16 + 25 = 55
    assert(range(1, 6):fold(0, function(acc, x) return acc + x * x end) == 55)
    assert(chain({}):sum() == nil)
    assert(chain({1}):sum() == 1)
    assert(range(1, 101):sum() == 5050)
    assert(range(1, 100):filter(function(x) return x % 2 == 0 end):max() == 98)
end

test(more_test, "more test")

function impl_test(  )
    local fab = chain(coroutine.wrap( function (  )
        local a, b = 0, 1
        while a < 100 do
            coroutine.yield( a )
            a, b = b, a + b
        end
    end ))

    assert(fab:enumerate():reduce(function(acc, x) return acc > x and acc or x end), 89)
end

test(impl_test, "impl test")