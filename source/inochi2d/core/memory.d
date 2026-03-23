/**
    Memory managment utilities.

    Copyright © 2026, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna Nielsen
*/
module inochi2d.core.memory;
import numem.core.hooks;
import numem;

/**
    Clears the given slice without freeing its memory.

    Params:
        slice = The slice to clear.
*/
void in_clear_slice(T)(ref T[] slice) @nogc {
    nu_free(cast(void*)slice.ptr);
    slice = null;
}