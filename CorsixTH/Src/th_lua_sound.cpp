/*
Copyright (c) 2010 Peter "Corsix" Cawley

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include "th_lua_internal.h"
#include "th_sound.h"

static int l_soundarc_new(lua_State *L)
{
    luaT_stdnew<THSoundArchive>(L, luaT_environindex, true);
    return 1;
}

static int l_soundarc_load(lua_State *L)
{
    THSoundArchive* pArchive = luaT_testuserdata<THSoundArchive>(L);
    size_t iDataLen;
    const unsigned char* pData = luaT_checkfile(L, 2, &iDataLen);

    if(pArchive->loadFromTHFile(pData, iDataLen))
        lua_pushboolean(L, 1);
    else
        lua_pushboolean(L, 0);
    return 1;
}

static int l_soundarc_count(lua_State *L)
{
    THSoundArchive* pArchive = luaT_testuserdata<THSoundArchive>(L);
    lua_pushnumber(L, (lua_Number)pArchive->getSoundCount());
    return 1;
}

static size_t l_soundarc_checkidx(lua_State *L, int iArg, THSoundArchive* pArchive)
{
    if(lua_isnumber(L, iArg))
    {
        size_t iIndex = (size_t)lua_tonumber(L, iArg);
        if(iIndex >= pArchive->getSoundCount())
        {
            lua_pushnil(L);
            lua_pushfstring(L, "Sound index out of "
                "bounds (%f is not in range [0, %d])", lua_tonumber(L, iArg),
                static_cast<int>(pArchive->getSoundCount()) - 1);
            return pArchive->getSoundCount();
        }
        return iIndex;
    }
    const char* sName = luaL_checkstring(L, iArg);
    lua_getfenv(L, 1);
    lua_pushvalue(L, iArg);
    lua_rawget(L, -2);
    if(lua_type(L, -1) == LUA_TLIGHTUSERDATA)
    {
        size_t iIndex = (size_t)lua_topointer(L, -1);
        lua_pop(L, 2);
        return iIndex;
    }
    lua_pop(L, 2);
    size_t iCount = pArchive->getSoundCount();
    for(size_t i = 0; i < iCount; ++i)
    {
        if(stricmp(sName, pArchive->getSoundFilename(i)) == 0)
        {
            lua_getfenv(L, 1);
            lua_pushvalue(L, iArg);
            lua_pushlightuserdata(L, (void*)i);
            lua_settable(L, -3);
            lua_pop(L, 1);
            return i;
        }
    }
    lua_pushnil(L);
    lua_pushliteral(L, "File not found in sound archive: ");
    lua_pushvalue(L, iArg);
    lua_concat(L, 2);
    return pArchive->getSoundCount();
}

static int l_soundarc_filename(lua_State *L)
{
    THSoundArchive* pArchive = luaT_testuserdata<THSoundArchive>(L);
    size_t iIndex = l_soundarc_checkidx(L, 2, pArchive);
    if(iIndex == pArchive->getSoundCount())
        return 2;
    lua_pushstring(L, pArchive->getSoundFilename(iIndex));
    return 1;
}

static int l_soundarc_duration(lua_State *L)
{
    THSoundArchive* pArchive = luaT_testuserdata<THSoundArchive>(L);
    size_t iIndex = l_soundarc_checkidx(L, 2, pArchive);
    if(iIndex == pArchive->getSoundCount())
        return 2;
    size_t iDuration = pArchive->getSoundDuration(iIndex);
    lua_pushnumber(L, static_cast<lua_Number>(iDuration) / static_cast<lua_Number>(1000));
    return 1;
}

static int l_soundarc_filedata(lua_State *L)
{
    THSoundArchive* pArchive = luaT_testuserdata<THSoundArchive>(L);
    size_t iIndex = l_soundarc_checkidx(L, 2, pArchive);
    if(iIndex == pArchive->getSoundCount())
        return 2;
    SDL_RWops *pRWops = pArchive->loadSound(iIndex);
    if(!pRWops)
        return 0;
    int iLength = SDL_RWseek(pRWops, 0, SEEK_END);
    SDL_RWseek(pRWops, 0, SEEK_SET);
    // There is a potential leak of pRWops if either of these Lua calls cause
    // a memory error, but it isn't very likely, and this a debugging function
    // anyway, so it isn't very important.
    void *pBuffer = lua_newuserdata(L, iLength);
    lua_pushlstring(L, (const char*)pBuffer,
        SDL_RWread(pRWops, pBuffer, 1, iLength));
    SDL_RWclose(pRWops);
    return 1;
}

static int l_soundarc_sound_exists(lua_State *L)
{
    THSoundArchive* pArchive = luaT_testuserdata<THSoundArchive>(L);
    size_t iIndex = l_soundarc_checkidx(L, 2, pArchive);
    if(iIndex == pArchive->getSoundCount())
        lua_pushboolean(L, 0);
    else
        lua_pushboolean(L, 1);
    return 1;
}

static int l_soundfx_new(lua_State *L)
{
    luaT_stdnew<THSoundEffects>(L, luaT_environindex, true);
    return 1;
}

static int l_soundfx_set_archive(lua_State *L)
{
    THSoundEffects *pEffects = luaT_testuserdata<THSoundEffects>(L);
    THSoundArchive *pArchive = luaT_testuserdata<THSoundArchive>(L, 2);
    pEffects->setSoundArchive(pArchive);
    lua_settop(L, 2);
    luaT_setenvfield(L, 1, "archive");
    return 1;
}

static int l_soundfx_set_sound_volume(lua_State *L)
{
    THSoundEffects *pEffects = luaT_testuserdata<THSoundEffects>(L);
    pEffects->setSoundEffectsVolume(luaL_checknumber(L, 2));
    return 1;
}

static int l_soundfx_set_sound_effects_on(lua_State *L)
{
    THSoundEffects *pEffects = luaT_testuserdata<THSoundEffects>(L);
    pEffects->setSoundEffectsOn(lua_toboolean(L, 2) != 0);
    return 1;
}

static int l_soundfx_play(lua_State *L)
{
    THSoundEffects *pEffects = luaT_testuserdata<THSoundEffects>(L);
    lua_settop(L, 5);
    lua_getfenv(L, 1);
    lua_pushliteral(L, "archive");
    lua_rawget(L, 6);
    THSoundArchive *pArchive = (THSoundArchive*)lua_touserdata(L, 7);
    if(pArchive == NULL)
    {
        return 0;
    }
    // l_soundarc_checkidx requires the archive at the bottom of the stack
    lua_replace(L, 1);
    size_t iIndex = l_soundarc_checkidx(L, 2, pArchive);
    if(iIndex == pArchive->getSoundCount())
        return 2;
    if(lua_isnil(L, 4))
    {
        pEffects->playSound(iIndex, luaL_checknumber(L, 3));
    }
    else
    {
        pEffects->playSoundAt(iIndex, luaL_checknumber(L, 3), luaL_checkint(L, 4), luaL_checkint(L, 5));
    }
    lua_pushboolean(L, 1);
    return 1;
}

static int l_soundfx_set_camera(lua_State *L)
{
    THSoundEffects *pEffects = luaT_testuserdata<THSoundEffects>(L);
    pEffects->setCamera(luaL_checkint(L, 2), luaL_checkint(L, 3), luaL_checkint(L, 4));
    return 0;
}

static int l_soundfx_reserve_channel(lua_State *L)
{
    int iChannel;
    THSoundEffects *pEffects = luaT_testuserdata<THSoundEffects>(L);
    iChannel = pEffects->reserveChannel();
    lua_pushinteger(L, iChannel);
    return 1;
}

static int l_soundfx_release_channel(lua_State *L)
{
    THSoundEffects *pEffects = luaT_testuserdata<THSoundEffects>(L);
    pEffects->releaseChannel(luaL_checkinteger(L, 2));
    return 1;
}

void THLuaRegisterSound(const THLuaRegisterState_t *pState)
{
    // Sound Archive
    luaT_class(THSoundArchive, l_soundarc_new, "soundArchive", MT_SoundArc);
    luaT_setmetamethod(l_soundarc_count, "len");
    luaT_setfunction(l_soundarc_load, "load");
    luaT_setfunction(l_soundarc_filename, "getFilename");
    luaT_setfunction(l_soundarc_duration, "getDuration");
    luaT_setfunction(l_soundarc_filedata, "getFileData");
    luaT_setfunction(l_soundarc_sound_exists, "soundExists");
    luaT_endclass();

    // Sound Effects
    luaT_class(THSoundEffects, l_soundfx_new, "soundEffects", MT_SoundFx);
    luaT_setfunction(l_soundfx_set_archive, "setSoundArchive", MT_SoundArc);
    luaT_setfunction(l_soundfx_play, "play");
    luaT_setfunction(l_soundfx_set_sound_volume, "setSoundVolume");
    luaT_setfunction(l_soundfx_set_sound_effects_on, "setSoundEffectsOn");
    luaT_setfunction(l_soundfx_set_camera, "setCamera");
    luaT_setfunction(l_soundfx_reserve_channel, "reserveChannel");
    luaT_setfunction(l_soundfx_release_channel, "releaseChannel");
    luaT_endclass();
}
