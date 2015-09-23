local cd = {}

local GetParas = function(parastring)
	local para = {}
	for p in string.gmatch(parastring, "([^,]+)") do
		local eq = string.find(p, "=")
		if eq then p = string.sub(p, 1, eq - 1) end
		local pp = string.match(p, "%s*(.+)%s[^%s]+")
		table.insert(para, pp)
	end
	return para
end

local FindCtor = function(ctor, line, name)
	local ctorpara = string.match(line, name .. "%((.-)%)")
	if ctorpara then
		local para = GetParas(ctorpara)
		table.insert(ctor, para)
		return true
	end
	return false
end

local FindPubMd = function(interface, line)
	local retv, iname, paras = string.match(line, "([^%s]+)%s+([%w_]+)%s*%((.-)%)")
	if retv then
		local itf = {}
		itf.retv = retv
		local para = GetParas(paras)
		if next(para) then
			itf.para = para
		end
		if interface[iname] then
			table.insert(interface[iname], itf)
		else
			interface[iname] = {itf}
		end
		return true
	end
	return false
end

cd.MakeClass = function(lines, index)
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
	local ctor = {}
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
				-- find constructors
				if not FindCtor(ctor, line, name) then
					-- find public methods
					if not FindPubMd(interface, line) then
						-- to do 
						-- find operators
					end
				end
			end
		end
		if string.find(line, "%*/") then annotation = false end
		index = index + 1
		line = lines[index]
	end

	if next(ctor) then
		class.constructor = ctor
	end
	if next(interface) then
		class.interface = interface
	end
	return name, class
end

cd.ClassDigger = function(file)
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
			local name, class = cd.MakeClass(lines, index)
			if name then
				classtable[name] = class
			end
		end
		if string.find(line, "%*/") then annotation = false end
	end
	return classtable
end

return cd
