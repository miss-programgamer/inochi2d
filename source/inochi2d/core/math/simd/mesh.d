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
    Performs deformation on the delta mesh.

    Params:
        mesh =      The mesh to deform.
        deform =    The mesh with the deformation deltas.
*/
void simd_deform(ref vec2[] mesh, vec2[] deform) @nogc nothrow {

    // Write length, in case there's a mismatch of sizes.
    size_t w_length = nu_min(mesh.length, deform.length);

    // Non-SIMD version
    if (w_length < IN_SIMD_THRESHOLD) {
        foreach(i; 0..w_length) {
            mesh[i] += deform[i];
        }
        return;
    }

    // SIMD version
    size_t i = 0;
    for (; i < nu_aligndown(w_length, 2); i += 2) {

        // Get 4 values at the same from both the mesh and deform.
        __m128 m_xyzw = _mm_loadu_ps(mesh[i].ptr);
        __m128 d_xyzw = _mm_loadu_ps(deform[i].ptr);

        // Add and store 2 vectors at the same time.
        __m128 xyzw = _mm_add_ps(m_xyzw, d_xyzw);
        _mm_store_ps(cast(float*)mesh[i].ptr, xyzw);
    }

    // Tail iteration to finalize the broadcast
    if (i < w_length) {
        __m128 m_xy01 = _mm_loadl_pi(IN_SIMD_IDENTITY, cast(const(__m64)*)mesh[i].ptr);
        __m128 d_xy01 = _mm_loadl_pi(IN_SIMD_IDENTITY, cast(const(__m64)*)deform[i].ptr);
        __m128 xy01 = _mm_add_ps(m_xy01, d_xy01);
        _mm_storel_pi(cast(__m64*)mesh[i].ptr, xy01);
    }
}

/**
    Broadcasts vertex data from the given delta mesh into
    the given VtxData mesh.

    SIMD is used in the case of larger meshes.

    Params:
        mesh =  The mesh to broadcast the deltas to.
        delta = The deltas to broadcast to the mesh.
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
    if (i < w_length) {
        __m128 xy01 = _mm_loadl_pi(IN_SIMD_IDENTITY, cast(const(__m64)*)mesh[i].vtx.ptr);
        _mm_storel_pi(cast(__m64*)mesh[i].vtx.ptr, xy01);
    }
}