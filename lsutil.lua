local util = {}

util.DumpTable = function(t, l)
	l = l or 0
	for k, v in pairs(t) do
		for i = 1, l do k = "\t" .. k end
		print(k, v)
		if type(v) == "table" then
			util.DumpTable(v, l + 1)
		end
	end
end

return util
