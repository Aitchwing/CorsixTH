/*
Copyright (c) 2009 Peter "Corsix" Cawley

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

#ifndef CORSIX_TH_CONFIG_H_
#define CORSIX_TH_CONFIG_H_

/** Rendering engine choice **/
// SDL - Multiplatform, but suboptimal on some platforms
// DX9 - Windows only, but always has HW accellerated alpha blitting
#ifdef _WIN32
#define CORSIX_TH_USE_DX9_RENDERER
#else
#define CORSIX_TH_USE_SDL_RENDERER
#endif

/** DX9 rendering engine options **/
// Uncomment the next line to render faster than the monitor refresh rate
// #define CORSIX_TH_DX9_UNLIMITED_FPS

/** Standard includes **/
#include <stddef.h>
#ifdef _MSC_VER
// MSVC doesn't have stdint.h, so define the types we want
typedef signed __int8 int8_t;
typedef signed __int16 int16_t;
typedef signed __int32 int32_t;
typedef unsigned __int8 uint8_t;
typedef unsigned __int16 uint16_t;
typedef unsigned __int32 uint32_t;
#else
#include <stdint.h>
#endif // _MSC_VER

#endif // CORSIX_TH_CONFIG_H_
