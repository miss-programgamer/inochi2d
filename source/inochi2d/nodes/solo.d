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
import numem;

/**
    A node which only allows a single child node to be displayed
    at a time.
*/
@TypeId("Solo", 0x0401)
class Solo : Visual {
private:
@nogc:
    uint activeLayer_;
    Visual[] visuals_;

    /**
        Changes the active layer.
    */
    void changeLayer(uint activeLayer) nothrow {
        if (children.length > 0) {
            this.activeLayer_ = clamp(activeLayer, 0, cast(uint)children.length);
            findVisuals(children[activeLayer_], visuals_);
        } else {
            if (visuals_) {
                nu_free(visuals_.ptr);
                visuals_ = null;
            }
        }
    }

protected:

    /**
        Called when the node is to be redrawn.
        
        Params:
            delta =     Time since the last frame.
            drawList =  The drawlist for the active scene.
            mode =      The masking mode to draw with.
    */
    override
    void onDraw(float delta, DrawList drawList, MaskingMode mode) {
        if (visuals_.length > 0) {
            sortNodes(visuals_);

            foreach(visual; visuals_) {
                if (!visual.enabled)
                    continue;

                visual.draw(delta, drawList);
            }
        }
    }

public:

    /**
        Whether the renderer should delegate rendering logic
        to the visual node.
    */
    override @property bool isDelegated() @nogc nothrow pure => true;
    
    /**
        The active layer that will be rendered.
    */
    final @property Node activeLayer() @nogc nothrow pure => children.length > 0 ? children[activeLayer_] : null;

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
        Gets whether a property with the given name exists
        in the object.

        Params:
            key = The name of the property.
        
        Returns:
            $(D true) if the property exists,
            $(D false) otherwise.
    */
    override
    bool hasProperty(string key) @nogc nothrow {
        switch (key) {
        case "activeLayer":
            return true;
        default:
            return super.hasProperty(key);
        }
    }

    /**
        Gets the value of a given property.

        Params:
            key = The name of the property.
        
        Returns:
            The floating point value of the property.
    */
    override
    float getProperty(string key) @nogc nothrow {
        switch (key) {
        case "activeLayer":
            return activeLayer_;
        default:
            return super.getProperty(key);
        }
    }

    /**
        Gets the default value of a given property.

        Params:
            key = The name of the property.
        
        Returns:
            The default value of the property.
    */
    override
    float getPropertyDefault(string key) @nogc nothrow {
        switch (key) {
        case "activeLayer":
            return 0;
        default:
            return super.getPropertyDefault(key);
        }
    }

    /**
        Sets the value of the property.

        Params:
            key =   The name of the property.
            value = The value to set the property to.
    */
    override
    void setProperty(string key, float value) @nogc nothrow {
        switch (key) {
        case "activeLayer":
            this.changeLayer(cast(uint)value);
            return;
        default:
            return super.setProperty(key, value);
        }
    }
}

mixin Register!(Solo, in_node_registry);
