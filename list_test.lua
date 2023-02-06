require("list")
require("test")

a = list{1, 2, 3, "jkl"}
b = list{false, list, a}
b:extend(a)
print(a)
print(b)

print(b:pop())
print(b)
print(b[{2, 5}])
print(a + b)
print(a)
print(b)
