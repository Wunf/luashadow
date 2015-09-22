#include "testclassA.hpp"
#include <stdlib.h>
#include <lua.hpp>
#include <lualib.h>
#include <lauxlib.h>

typedef void (*ClassACtor)(lua_State * L);

static int ClassActor(lua_State * L)
{
	GenClassAMTable(L);

	int n = lua_gettop(L);
	char buffer[100];
	sprintf(buffer, "%d", n);
	string mkey = "ClassActor";
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

	lua_getglobal(L, "ClassAmtable");
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
	ClassACtor func = (ClassACtor)lua_touserdata(L, -1);

	lua_newtable(L);
	luaL_setfuncs(L, gClassAFuncs, 0);
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");
	func(L);
	lua_setfield(L, -2, "rawptr");
	return 1;
}

static const luaL_Reg gClasses[] = {
	{"ClassA", ClassActor},
	{NULL, NULL}
};

extern "C" {
int luaopen_test(lua_State * L)
{
	luaL_newlib(L, gClasses);
	return 1;
}
}
