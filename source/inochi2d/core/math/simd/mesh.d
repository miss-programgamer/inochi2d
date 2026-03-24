/**
    Inochi2D Mesh SIMD Helpers

    Copyright © 2025, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inochi2d.core.math.simd.mesh;
import inochi2d.core.math.simd;
import inochi2d.core.mesh;
import numem.core.math;
import inmath.linalg;
import inmath.math;
import inmath.util;
import inteli;

/**
    Broadcasts vertex data from the given delta mesh into
    the given VtxData mesh.

    SIMD is used in the case of larger meshes.
*/
void simd_broadcast_mesh(ref VtxData[] mesh, vec2[] delta) @nogc nothrow {

    // Write length, in case there's a mismatch of sizes.
    size_t w_length = nu_min(mesh.length, delta.length);

    // Non-SIMD version
    if (mesh.length < IN_SIMD_THRESHOLD) {
        foreach(i; 0..w_length) {
            mesh[i].vtx.vector[0..2] += delta[i].vector[0..2];
        }
        return;
    }

    // SIMD version
    size_t i = 0;
    for (; i < nu_aligndown(w_length, 2); i += 2) {

        // Load vectors into SIMD variables, then uses SIMD store
        // to write it to the XY components of the VtxDatas.
        __m128 xy01 = _mm_loadl_pi(IN_SIMD_IDENTITY, cast(const(__m64)*)delta[i].ptr);
        __m128 zw01 = _mm_loadl_pi(IN_SIMD_IDENTITY, cast(const(__m64)*)delta[i+1].ptr);
        _mm_storel_pi(cast(__m64*)mesh[i].vtx.ptr, xy01);
        _mm_storel_pi(cast(__m64*)mesh[i+1].vtx.ptr, zw01);
    }

    // Tail iteration to finalize the broadcast
    if (i < mesh.length) {
        __m128 xy01 = _mm_loadl_pi(IN_SIMD_IDENTITY, cast(const(__m64)*)mesh[i].vtx.ptr);
        _mm_storel_pi(cast(__m64*)mesh[i].vtx.ptr, xy01);
    }
}