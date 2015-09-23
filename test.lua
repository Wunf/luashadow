local cd = require("lsclassdigger")
local util = require("lsutil")
local gl = require("lsgenlib")

local classtable = cd.ClassDigger("classA.h")
if next(classtable) then
	gl.GenLibCFile(classtable, "sample.c")
	--util.DumpTable(classtable, 0)
end
