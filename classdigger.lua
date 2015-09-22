local MakeClass = function(lines, index)
	local line = lines[index]

	-- class name and base class names
	local before, after = line:match("%s*class%s+(.+)%s*:%s*(.+)")
	if not before then
		before = line:match("%s*class%s+([^;]+)%s*$")
	end
	local class = {}
	if not before then return nil end
	local name = before:match(".-([^%s]+)%s*$")
	if not name then return nil end
	local base = {}
	if after and #after ~= 0 then
		for bname in string.gmatch(after, "([^,%s]+)") do
			if bname ~= "public" and bname ~= "private" then
				table.insert(base, bname)
			end
		end
	end
	if next(base) then
		class.base = base
	end

	-- all the public methods
	local interface = {}
	local public = false 
	local annotation = false
	while line and not string.match(line, "%s*};%s*") do
		if string.find(line, "/%*") then annotation = true end
		if not string.match(line, "^%s*//") and not annotation then
			if string.match(line, "%s*public%s*:%s*") then
				public = true
			end
			if string.match(line, "%s*private%s*:%s*") or string.match(line, "%s*protected%s*:%s*") then
				public = false
			end
			if public then
				local retv, iname, paras = string.match(line, "([^%s]+)%s+([%w_]+)%s*%((.-)%)")
				if retv then
					local itf = {}
					itf.retv = retv
					local para = {}
					for p in string.gmatch(paras, "([^,]+)") do
						local eq = string.find(p, "=")
						if eq then p = string.sub(p, 1, eq - 1) end
						local pp = string.match(p, "%s*(.+)%s[^%s]+")
						table.insert(para, pp)
					end
					if next(para) then
						itf.para = para
					end
					interface[iname] = itf
				end
			end
		end
		if string.find(line, "%*/") then annotation = false end
		index = index + 1
		line = lines[index]
	end
	if next(interface) then
		class.interface = interface
	end
	return name, class
end

local ClassDigger = function(file)
	if not file then return nil end
	local f = io.open(file, "r")
	local lines = {}
	local classtable = {}
	for line in f:lines() do
		table.insert(lines, line)
	end
	local annotation = false
	for index, line in ipairs(lines) do
		if string.find(line, "/%*") then annotation = true end
		if not annotation and not string.match(line, "^%s*//") and line:match("%s*class%s+") then
			local name, class = MakeClass(lines, index)
			if name then
				classtable[name] = class
			end
		end
		if string.find(line, "%*/") then annotation = false end
	end
	return classtable
end

DumpTable = function(t, l)
	l = l or 0
	for k, v in pairs(t) do
		for i = 1, l do k = "\t" .. k end
		print(k, v)
		if type(v) == "table" then
			DumpTable(v, l + 1)
		end
	end
end

local classtable = ClassDigger(arg[1])
if next(classtable) then
	DumpTable(classtable, 0)
end
