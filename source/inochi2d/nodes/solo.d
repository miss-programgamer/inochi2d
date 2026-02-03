/**
    Inochi2D Solo Node

    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Luna Nielsen
*/
module inochi2d.nodes.solo;
import inochi2d.nodes.visual;
import inochi2d.nodes;
import inochi2d.core.math;
import inochi2d.core;

/**
    A node which only allows a single child node to be displayed
    at a time.
*/
@TypeId("Solo", 0x0401)
class Solo : Visual {
private:
@nogc:
    uint activeLayer;

protected:

    override
    void onDraw(float delta, DrawList drawList, MaskingMode mode) {

    }

public:

    /**
        Constructs a new Solo node.

        Params:
            parent = The parent of the solo node.
    */
    this(Node parent = null) {
        super(inNewGUID(), parent);
    }

    /**
        Constructs a new Solo node.

        Params:
            guid =      The new GUID of the
            parent =    The parent of the solo node.
    */
    this(GUID guid, Node parent = null) {
        super(guid, parent);
    }

    /**
        Whether the renderer should delegate rendering logic
        to the visual node.
    */
    override @property bool isDelegated() @nogc => true;
}

mixin Register!(Solo, in_node_registry);
