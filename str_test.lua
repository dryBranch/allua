require("test")
local str = require("str")

function basic_test(  )
    local s = "\n ==abc== fdfd== \n  "
    assert(str.trim(s) == "==abc== fdfd==")
    assert(str.ltrim(s) == "==abc== fdfd== \n  ")
    assert(str.rtrim(s) == "\n ==abc== fdfd==")
    cmp(
        str.split("lionXXtigerXleopard", "X"),
        {"lion", "", "tiger", "leopard"}
    )
    assert(str.format("name = $1, age = $2", {"tom", 18}) == "name = tom, age = 18")
end

test(basic_test, "basic test")