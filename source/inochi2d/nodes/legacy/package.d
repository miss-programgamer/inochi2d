/**
    Inochi2D Legacy Nodes for backwards compatibility.

    Copyright © 2022-2026, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors:
        Luna Nielsen
        Hoshino Lina
*/
module inochi2d.nodes.legacy;

// Allow disabling legacy nodes.
version (IN_NO_LEGACY) {
} else:

    public import inochi2d.nodes.legacy.simplephysics;
