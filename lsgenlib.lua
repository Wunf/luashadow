local gl = {}

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

gl.GenLibClassHpp = function(class, classtbl)
end

gl.GenLibMakeFile = function()
end

return gl
