/**
    Inochi2D SIMD Helpers

    Copyright © 2025, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inochi2d.core.math.simd;
import inteli;

public import inochi2d.core.math.simd.matrix;
public import inochi2d.core.math.simd.vector;
public import inochi2d.core.math.simd.mesh;

/**
    The minimum threshold size of a mesh before SIMD operations kick in.
*/
enum IN_SIMD_THRESHOLD = 100;

/**
    An identity 4-dimensional vector.
*/
static const __m128 IN_SIMD_IDENTITY = __m128([0, 0, 0, 1]);