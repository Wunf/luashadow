#include "testclassA.hpp"
#include <stdlib.h>
#include <lua.hpp>
#include <lualib.h>
#include <lauxlib.h>

static int ClassActor(lua_State * L)
{
	GenClassAMTable(L);
	luaL_checknumber(L, 1);
	int arg1 = lua_tonumber(L, -1);
	lua_newtable(L);
	luaL_setfuncs(L, gClassAFuncs, 0);
	lua_pushvalue(L, -1);
	lua_setfield(L, -2, "__index");
	ClassA * pa = new ClassA(arg1);
	lua_pushlightuserdata(L, (void*)pa);
	lua_setfield(L, -2, "class");
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
