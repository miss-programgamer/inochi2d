/**
    Inochi2D WebAssembly Integration.

    Copyright © 2020-2025, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inochi2d.core.sys.wasm;
import etc.c.zlib : z_stream, deflateInit_, inflateInit_;
import core.stdc.errno;

version(WebAssembly):

extern(C) export @nogc nothrow:

int deflateInit(z_stream* strm, int level) { return deflateInit_(strm, level, "1.3.1", z_stream.sizeof); }
int inflateInit(z_stream* strm) { return inflateInit_(strm, "1.3.1", z_stream.sizeof); }

int getErrno() { return errno; }
int setErrno(int value) { errno = value; return errno; }