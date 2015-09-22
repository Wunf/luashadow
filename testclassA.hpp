#ifndef __TEST_CLASSA_HPP__
#define __TEST_CLASSA_HPP__

#include "classA.h"
#include <lua.hpp>
#include <lualib.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <string>

using namespace std;

// lua 5.2 feature
#define luaL_checkint(L, n) ((int)luaL_checkinteger(L, (n)))

typedef int (*ClassAMethods)(lua_State * L, ClassA*);
static void ClassActor0(lua_State * L);
static void ClassActor1n(lua_State * L);
static int sayhi(lua_State * L);
static int sayhi0(lua_State * L, ClassA * ca);
static int sayhi1n(lua_State * L, ClassA * ca);
static int sayhi2nn(lua_State * L, ClassA * ca);

// interface
const luaL_Reg gClassAFuncs[] = {
	{"sayhi", sayhi},
	{NULL, NULL}
};

void GenClassAMTable(lua_State * L)
{
	lua_getglobal(L, "ClassAmtable");
	if(lua_istable(L, -1))
	{	
		lua_pop(L, 1);
		return;
	}
	lua_pop(L, 1);
	lua_newtable(L);

	lua_pushlightuserdata(L, (void*)&ClassActor0);
	lua_setfield(L, -2, "ClassActor0");
	lua_pushlightuserdata(L, (void*)&ClassActor1n);
	lua_setfield(L, -2, "ClassActor1n");
	lua_pushlightuserdata(L, (void*)&sayhi0);
	lua_setfield(L, -2, "sayhi0");
	lua_pushlightuserdata(L, (void*)&sayhi1n);
	lua_setfield(L, -2, "sayhi1n");
	lua_pushlightuserdata(L, (void*)&sayhi2nn);
	lua_setfield(L, -2, "sayhi2nn");

	lua_setglobal(L, "ClassAmtable");
} 

static void ClassActor0(lua_State * L)
{
	ClassA * p = new ClassA();
	lua_pushlightuserdata(L, (void*)p);
}

static void ClassActor1n(lua_State * L)
{
	int a = (int)luaL_checkinteger(L, 1);
	ClassA * p = new ClassA(a);
	lua_pushlightuserdata(L, (void*)p);
}

static int sayhi0(lua_State * L, ClassA * ca)
{
	ca->sayhi();
	return 0;
}

static int sayhi1n(lua_State * L, ClassA * ca)
{
	int a = luaL_checkint(L, 2);
	ca->sayhi(a);	
	return 0;
}
	
static int sayhi2nn(lua_State * L, ClassA * ca)
{
	int a = luaL_checkint(L, 2);
	int b = luaL_checkint(L, 3);
	ca->sayhi(a, b);	
	return 0;
}

static int sayhi(lua_State * L)
{
	int n = lua_gettop(L);
	char buffer[100];
	sprintf(buffer, "%d", n - 1);
	string mkey = "sayhi"; 
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
	ClassA * ca = (ClassA*)lua_touserdata(L, -1);

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
	ClassAMethods func = (ClassAMethods)lua_touserdata(L, -1);
	func(L, ca);
	return 0;
}

#endif
