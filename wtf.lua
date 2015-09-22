local test = require("test")

local objA1 = test.ClassA(1)
local objA2 = test.ClassA()

objA1:sayhi()
objA1:sayhi(100)
objA1:sayhi(9, 777)
objA2:sayhi()
