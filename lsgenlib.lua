local gl = {}

local paracodetable = {
	int = "\tint p%d = (int)luaL_checkinteger(L, %d);\n",
	long = "\tint p%d = (long)luaL_checkinteger(L, %d);\n",
	double = "\tint p%d = (double)luaL_checknumber(L, %d);\n",
	float = "\tint p%d = (float)luaL_checknumber(L, %d);\n",
	pointer = "\t%s * p%d = (%s*)luaL_checkudata(L, %d);\n",
	bool = "\tluaL_checktype(L, %d, 1);\n\tbool p%d = (bool)lua_toboolean(L, %d);\n",
	string = "\tconst char * p%d = (const char*)luaL_checkstring(L, %d);\n"
}

local GenLuaCCtor = function(name)
	local func = 
[[
static int XXXXXctor(lua_State * L)
{
	GenXXXXXMTable(L);

	int n = lua_gettop(L);
	char buffer[100];
	sprintf(buffer, "%d", n);
	string mkey = "XXXXXctor";
	mkey += buffer;
	for(int i = -n; i < 0; ++i)
	{
		int t = lua_type(L, i);	
		switch(t)
		{
		case LUA_TSTRING:
			mkey += "s";
			break;
		case LUA_TBOOLEAN:
			mkey += "b";
			break;
		case LUA_TNUMBER:
			mkey += "n";
			break;
		case LUA_TLIGHTUSERDATA:
			mkey += "p";
			break;
		default:
			lua_pushstring(L, "bad parameter");
			lua_error(L);
		}
	}

	lua_getglobal(L, "XXXXXmtable");
	if(!lua_istable(L, -1))
	{	
		lua_pushstring(L, "mtable not found");
		lua_error(L);
	}
	if(lua_getfield(L, -1, mkey.c_str()) != LUA_TLIGHTUSERDATA)
	{	
		lua_pushstring(L, "mkey not found");
		lua_error(L);
	}
	XXXXXCtor func = (XXXXXCtor)lua_touserdata(L, -1);

	lua_newtable(L);
	luaL_setfuncs(L, gXXXXXFuncs, 0);
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");
	func(L);
	lua_setfield(L, -2, "rawptr");
	return 1;
}

]]
	func = string.gsub(func, "XXXXX", name)
	return func
end

gl.GenLibCFile = function(classtbl, filename)
	local file = ""
	for name, _ in pairs(classtbl) do
		file = file .. string.format("#include \"ls%s.hpp\"\n", name)
	end
	file = file .. 
[[
#include <lua.hpp>
#include <lualib.h>
#include <lauxlib.h>
#include <string>

using namespace std;

]]
	for name, _ in pairs(classtbl) do
		file = file .. string.format("typedef void (*%sCtor)(lua_State * L);\n\n", name)
	end
	for name, _ in pairs(classtbl) do
		file = file .. GenLuaCCtor(name)
	end
	file = file .. 
[[
static const luaL_Reg gClasses[] = {
]]
	for name, _ in pairs(classtbl) do
		file = file .. string.format("\t{\"%s\", %sctor},\n", name, name)
	end
	file = file .. 
[[	{NULL, NULL}
};

extern "C" {
int luaopen_luashadow(lua_State * L)
{
	luaL_newlib(L, gClasses);
	return 1;
}
}
]]
	local f, err = io.open(filename, "w")
	if not f then print(err) end
	f:write(file)
	f:flush()
	f:close()
end

gl.GenLibClassHpp = function(class, classheaderfile, classtbl)
	local classinfo = classtbl[class]
	local file = ""
	file = file .. string.format("#ifndef __TEST_%s_HPP__\n", string.upper(class))
	file = file .. string.format("#define __TEST_%s_HPP__\n\n", string.upper(class))
	file = file .. string.format("#include \"%s\"\n", classheaderfile)
	file = file .. 
[[
#include <lua.hpp>
#include <lualib.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <string>

using namespace std;

]]
	local funcnames = {}
	local ctornames = {}
	file = file .. string.format("typedef int (*%sMethods)(lua_State * L, %s*);\n", class, class);
	local ctors = classinfo.constructor
	for _, para in ipairs(ctors) do
		local p = ""
		for _, t in ipairs(para) do
			if t == "int" or t == "double" or t == "float" or t == "long" then
				p = p .. "n"
			elseif t == "bool" then
				p = p .. "b"
			elseif t == "const char *" or t == "const char*" or t == "char *" or t == "char*" then
				p = p .. "t"
			elseif string.find(t, "%*") then 
				p = p .. "p"
			else
				print("!!! unknow cpp type !!!")
			end
		end
		local name = string.format("%sctor%d%s", class, #para, p)
		table.insert(ctornames, name)
		file = file .. string.format("static void %s(lua_State * L);\n", name)
	end

	local itfs = classinfo.interface
	for f, info in pairs(itfs) do
		funcnames[f] = {}
		file = file .. string.format("static int %s(lua_State * L);\n", f)
		for _, i in ipairs(info) do
			local p = ""
			if i.para then
				for _, t in ipairs(i.para) do
					if t == "int" or t == "double" or t == "float" or t == "long" then
						p = p .. "n"
					elseif t == "bool" then
						p = p .. "b"
					elseif t == "const char *" or t == "const char*" or t == "char *" or t == "char*" then
						p = p .. "t"
					elseif string.find(t, "%*") then 
						p = p .. "p"
					else
						print("!!! unknow cpp type !!!")
					end
				end
			end
			local pn = 0
			if i.para then pn = #i.para end
			local name = string.format("%s%d%s", f, pn, p)
			table.insert(funcnames[f], name)
			file = file .. string.format("static int %s(lua_State * L, %s * p);\n", name, class)
		end
			
	end
	file = file .. "\n"
	file = file .. string.format(
[[
// interface
const luaL_Reg g%sFuncs[] = {
]]
	, class)
	for f, _ in pairs(itfs) do
		file = file .. string.format("\t{\"%s\", %s},\n", f, f)
	end
	file = file .. string.format(
[[
	{NULL, NULL}
};

void Gen%sMTable(lua_State * L)
{
	lua_getglobal(L, "%smtable");
	if(lua_istable(L, -1))
	{	
		lua_pop(L, 1);
		return;
	}
	lua_pop(L, 1);
	lua_newtable(L);

]]
	, class, class)
	for _, name in ipairs(ctornames) do
		file = file .. string.format(
[[
	lua_pushlightuserdata(L, (void*)&%s);
	lua_setfield(L, -2, "%s");
]]
		, name, name)
	end
	for k, names in pairs(funcnames) do
		for _, name in ipairs(names) do
			file = file .. string.format(
[[
	lua_pushlightuserdata(L, (void*)&%s);
	lua_setfield(L, -2, "%s");
]]
			, name, name)
		end
	end
	file = file .. "\n"
	file = file .. string.format(
[[
	lua_setglobal(L, "%smtable");
} 

]]
	, class)

	for i, para in ipairs(ctors) do
		file = file .. string.format("static void %s(lua_State * L)\n{\n", ctornames[i])
		for j, t in ipairs(para) do
			if t == "int" then
				file = file .. string.format(paracodetable["int"], j, j)
			elseif t == "long" then
				file = file .. string.format(paracodetable["long"], j, j)
			elseif t == "double" then
				file = file .. string.format(paracodetable["double"], j, j)
			elseif t == "float" then
				file = file .. string.format(paracodetable["float"], j, j)
			elseif t == "bool" then
				file = file .. string.format(paracodetable["bool"], j, j)
			elseif t == "const char *" or t == "const char*" or t == "char *" or t == "char*" then
				file = file .. string.format(paracodetable["string"], j, j)
			elseif string.find(t, "%*") then 
				local tname = string.match(t, "(.-)%s*%*")
				file = file .. string.format(paracodetable["pointer"], t, j, t, j)
			else
				print("!!! unknow cpp type !!!")
			end
		end
		local plist = ""
		if #para > 0 then
			plist = "p1"
		end
		for i = 2, #para do 
			plist = plist .. string.format(", p%d", i)
		end
		file = file .. string.format("\t%s * p = new %s(%s);\n\tlua_pushlightuserdata(L, (void*)p);\n}\n\n", class, class, plist)
	end

	for f, info in pairs(itfs) do
		for i, fi in ipairs(info) do
			file = file .. string.format("static int %s(lua_State * L, %s * p)\n{\n", funcnames[f][i], class)
			if fi.para then
				for j, t in ipairs(fi.para) do
					if t == "int" then
						file = file .. string.format(paracodetable["int"], j, j + 1)
					elseif t == "long" then
						file = file .. string.format(paracodetable["long"], j, j + 1)
					elseif t == "double" then
						file = file .. string.format(paracodetable["double"], j, j + 1)
					elseif t == "float" then
						file = file .. string.format(paracodetable["float"], j, j + 1)
					elseif t == "bool" then
						file = file .. string.format(paracodetable["bool"], j, j + 1)
					elseif t == "const char *" or t == "const char*" or t == "char *" or t == "char*" then
						file = file .. string.format(paracodetable["string"], j, j + 1)
					elseif string.find(t, "%*") then 
						local tname = string.match(t, "(.-)%s*%*")
						file = file .. string.format(paracodetable["pointer"], t, j, t, j + 1)
					else
						print("!!! unknow cpp type !!!")
					end
				end
			end
			local plist = ""
			if fi.para and #fi.para > 0 then
				plist = "p1"
			end
			if fi.para then
				for i = 2, #fi.para do 
					plist = plist .. string.format(", p%d", i)
				end
			end
			if fi.retv == "void" then
				file = file .. string.format("\tp->%s(%s);\n\treturn 0;\n}\n\n", f, plist)
			else
				file = file .. string.format("\t%s r = p->%s(%s);\n", fi.retv, f, plist)
				local t = fi.retv
				if t == "int" or t == "double" or t == "float" or t == "long" then
					file = file .. "\tlua_pushnumber(L, (lua_Number)r);\n"
				elseif t == "bool" then
					file = file .. "\tlua_pushboolean(L, (int)r);\n"
				elseif t == "const char *" or t == "const char*" or t == "char *" or t == "char*" then
					file = file .. "\tlua_pushstring(L, r);\n"
				elseif string.find(t, "%*") then 
					file = file .. "\tlua_pushlightuserdata(L, (void*)r);\n"
				else
					print("!!! unknow cpp type !!!")
				end
				file = file .. "\treturn 1;\n}\n\n"
			end
		end
	end

	for f, info in pairs(itfs) do
		file = file .. string.format(
[[
static int %s(lua_State * L)
{
	int n = lua_gettop(L);
	char buffer[100];
	sprintf(buffer, "%%d", n - 1);
	string mkey = "%s"; 
	mkey += buffer;
	for(int i = 1 - n; i < 0; ++i)
	{
		int t = lua_type(L, i);	
		switch(t)
		{
		case LUA_TSTRING:
			mkey += "s";
			break;
		case LUA_TBOOLEAN:
			mkey += "b";
			break;
		case LUA_TNUMBER:
			mkey += "n";
			break;
		case LUA_TLIGHTUSERDATA:
			mkey += "p";
			break;
		default:
			lua_pushstring(L, "bad parameter");
			lua_error(L);
		}
	}
	
	luaL_checktype(L, 1, LUA_TTABLE);
	lua_getfield(L, -n, "rawptr");
	if(!lua_islightuserdata(L, -1))
	{
		lua_pushstring(L, "missing pointer");
		lua_error(L);
	}
	%s * p = (%s*)lua_touserdata(L, -1);

	lua_getglobal(L, "%smtable");
	if(!lua_istable(L, -1))
	{	
		lua_pushstring(L, "mtable not found");
		lua_error(L);
	}
	if(lua_getfield(L, -1, mkey.c_str()) != LUA_TLIGHTUSERDATA)
	{	
		lua_pushstring(L, "mkey not found");
		lua_error(L);
	}
	%sMethods func = (%sMethods)lua_touserdata(L, -1);
	return func(L, ca);
}

]]
		, f, f, class, class, class, class, class)
	end
	file = file ..
[[
#endif
]]
	local f, err = io.open(string.format("ls%s.hpp", class), "w")
	if not f then print(err) end
	f:write(file)
	f:flush()
	f:close()
end

gl.GenLibMakeFile = function()
end

return gl
