/*
    Inochi2D Node

    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inochi2d.core.nodes;
import inochi2d.core.serde;
import inochi2d.core.math;
import inochi2d.core.guid;
import inochi2d.core;
import nulib.string;
import numem;
import nulib;

public import inochi2d.core.nodes.composite;
public import inochi2d.core.nodes.deformer;
public import inochi2d.core.nodes.drivers; 
public import inochi2d.core.nodes.visual;
public import inochi2d.core.nodes.part;
public import inochi2d.core.nodes.animatedpart;
public import inochi2d.core.registry;
public import inochi2d.core.property;

import core.attribute : standalone;
import std.exception;

/**
    The public node registry.
*/
__gshared TypeRegistry!Node in_node_registry;

/**
    A node in the Inochi2D rendering tree
*/
@TypeId("Node", 0x00000000)
class Node : NuRefCounted, ISerializable, IDeserializable {
private:
    Puppet puppet_;
    Node parent_;
    weak_vector!Node children_;
    GUID guid_;
    float zsort_ = 0;
    bool lockToRoot_;
    string nodePath_;
    uint nid_;
    bool recalculateTransform = true;

package(inochi2d):

    /**
        Needed for deserialization
    */
    void setPuppet(Puppet puppet) @nogc {
        this.puppet_ = puppet;
    }

protected:

    /**
        The Node's numeric ID
    */
    final @property uint nid() @nogc pure => nid_;

    /**
        The offset to the transform to apply
    */
    Transform transformOffset;

    /**
        The offset to apply to sorting
    */
    float offsetSort = 0f;

    // Send mask reset request one node up
    void resetMask() {
        if (parent !is null) parent.resetMask();
    }

    /**
        Serializes this node to a DataNode.

        Params:
            object =    The DataNode to serialize to.
            recursive = Whether to recurse through children.
    */
    void onSerialize(ref DataNode object, bool recursive = true) @nogc {
        nstring guid = guid_.toString();
        object["guid"] = guid[];
        object["name"] = name[];
        object["type"] = typeId.sid;
        object["enabled"] = enabled;
        object["zsort"] = zsort_;
        object["transform"] = zsort_;
        object["lockToRoot"] = lockToRoot_;

        // Recurse through children if enabled.
        if (recursive) {
            object["children"] = DataNode.createArray();
            foreach(child; children) {
                auto childObject = DataNode.createObject();
                child.serialize(childObject);

                object["children"] ~= childObject;
            }
        }
    }

    /**
        Deserializes this node from a DataNode.

        Params:
            object = The DataNode to deserialize from.
    */
    void onDeserialize(ref DataNode object) @nogc {

        this.guid_ = object.tryGetGUID("uuid", "guid");
        object.tryGetRef(name, "name");
        object.tryGetRef(enabled, "enabled");
        object.tryGetRef(zsort_, "zsort");
        object.tryGetRef(localTransform, "transform");
        object.tryGetRef(lockToRoot_, "lockToRoot");

        // Pre-populate our children with the correct types
        if ("children" in object && object["children"].isArray) {
            foreach(ref child; object["children"].array) {
                
                // Fetch type from json
                if (string type = child.tryGet!string("type", null)) {

                    // Skips unknown node types
                    // TODO: A logging system that shows a warning for this?
                    if (!in_node_registry.has(type))
                        continue;

                    // NOTE:    inInstantiateNode implicitly handles setting the
                    //          Parent-child relationship, so we don't need to do
                    //          anything else besides pass it onto the child's
                    //          deserializer.
                    Node n = in_node_registry.create(type);
                    n.parent = this;
                    child.deserialize(n);
                }
            }
        }
    }

    /**
        Called when the node is to finalize its deserialization from disk.
    */
    void onFinalize() @nogc {
        nid_ = typeId.nid;
        foreach(child; children) {
            child.onFinalize();
        }
    }

    /**
        Called during the early update phase of a new frame.
        
        Params:
            drawList =  The drawlist for the active scene.
    */
    void onPreUpdate(DrawList drawList) @nogc { }

    /**
        Called during the update phase of a new frame.
        
        Params:
            delta =     Time since the last frame.
            drawList =  The drawlist for the active scene.
    */
    void onUpdate(float delta, DrawList drawList) @nogc { }

    /**
        Called during the late update phase of a new frame.
        
        Params:
            drawList =  The drawlist for the active scene.
    */
    void onPostUpdate(DrawList drawList) @nogc { }

    /**
        Called when the node is to be redrawn.
        
        Params:
            delta =     Time since the last frame.
            drawList =  The drawlist for the active scene.
            mode =      The masking mode to draw with.
    */
    void onDraw(float delta, DrawList drawList, MaskingMode mode = MaskingMode.none) @nogc { }

public:

    /**
        Whether the node is enabled
    */
    bool enabled = true;

    /**
        Visual name of the node
    */
    nstring name = "Unnamed Node";

    /**
        The Node's Type ID
    */
    final @property TypeId typeId() @nogc => in_node_registry.lookup(this);

    /**
        The node's GUID.
    */
    @property GUID guid() @nogc nothrow pure => guid_;

    /**
        Whether the node is enabled for rendering

        Disabled nodes will not be drawn.

        This happens recursively
    */
    @property bool renderEnabled() @nogc nothrow pure => parent ? (!parent.renderEnabled ? false : enabled) : enabled;

    /**
        The relative Z sorting
    */
    @property ref float relZSort() @nogc nothrow pure => zsort_;

    /**
        The basis zSort offset.
    */
    @property float zSortBase() @nogc nothrow pure => parent !is null ? parent.zSort() : 0;

    /**
        The Z sorting without parameter offsets
    */
    @property float zSortNoOffset() @nogc nothrow pure => zSortBase + relZSort;

    /**
        The Z sorting
    */
    @property float zSort() @nogc nothrow pure => zSortBase + relZSort + offsetSort;
    @property void zSort(float value) @nogc nothrow pure {
        zsort_ = value;
    }

    /**
        Lock translation to root
    */
    @property bool lockToRoot() @nogc nothrow pure => lockToRoot_;
    @property void lockToRoot(bool value) @nogc {
        
        // Automatically handle converting lock space and proper world space.
        if (value && !lockToRoot_) {
            localTransform.translation = transformNoLock().translation;
        } else if (!value && lockToRoot_) {
            localTransform.translation = localTransform.translation-parent.transformNoLock().translation;
        }

        lockToRoot_ = value;
    }

    ~this() {
        foreach(child; children_) {
            child.release();
        }
        children_.clear();
    }

    /**
        Constructs a new puppet root node
    */
    this(Puppet puppet) @nogc {
        this.puppet_ = puppet;
        this.guid_ = inNewGUID();
    }

    /**
        Constructs a new node
    */
    this(Node parent = null) @nogc {
        this(inNewGUID(), parent);
    }

    /**
        Constructs a new node with an UUID
    */
    this(GUID guid, Node parent = null) @nogc {
        this.parent = parent;
        this.guid_ = guid;
    }

    /**
        The local transform of the node
    */
    Transform localTransform;

    /**
        The cached world space transform of the node
    */
    Transform globalTransform;

    /**
        The transform in world space
    */
    @property Transform transform(bool ignoreParam=false)() @nogc {
        static if (!ignoreParam) {
            if (recalculateTransform) {
                localTransform.update();
                transformOffset.update();
                if (lockToRoot_)
                    globalTransform = localTransform.calcOffset(transformOffset) * puppet.root.localTransform;
                else if (parent !is null)
                    globalTransform = localTransform.calcOffset(transformOffset) * parent.transform();
                else
                    globalTransform = localTransform.calcOffset(transformOffset);

                recalculateTransform = false;
            }
            return globalTransform;

        } else {
            Transform mts;
            if (lockToRoot_)
                mts = localTransform * puppet.root.localTransform;
            else if (parent !is null)
                mts = localTransform * parent.transform();
            else
                mts = localTransform;
            
            return mts;
        }
    }

    /**
        The transform in world space without locking
    */
    @property Transform transformLocal() @nogc {
        localTransform.update();
        
        return localTransform.calcOffset(transformOffset);
    }

    /**
        The transform in world space without locking
    */
    @property Transform transformNoLock() @nogc {
        localTransform.update();
        
        if (parent !is null) return localTransform * parent.transform();
        return localTransform;
    }

    /**
        Gets a list of this node's children
    */
    final @property Node[] children() @nogc nothrow pure => children_;

    /**
        The parent of this node
    */
    final @property Node parent() @nogc nothrow pure => parent_;
    final @property void parent(Node node) @nogc {
        this.insertInto(node, OFFSET_END);
    }

    /**
        The puppet this node is attached to
    */
    final @property Puppet puppet() @nogc nothrow pure => parent_ !is null ? parent_.puppet : puppet_;

    /**
        Calculates the relative position between 2 nodes and applies the offset.
        You should call this before reparenting nodes.
    */
    void setRelativeTo(Node to) {
        setRelativeTo(to.transformNoLock.matrix);
        this.zSort = this.zSortNoOffset-to.zSortNoOffset;
    }

    /**
        Calculates the relative position between this node and a matrix and applies the offset.
        This does not handle zSorting. Pass a Node for that.
    */
    void setRelativeTo(mat4 to) {
        this.localTransform.translation = getRelativePosition(to, this.transformNoLock.matrix);
        this.localTransform.update();
    }

    /**
        Gets a relative position for 2 matrices
    */
    static
    vec3 getRelativePosition(mat4 m1, mat4 m2) {
        mat4 cm = (m1.inverse * m2).translation;
        return vec3(cm.matrix[0][3], cm.matrix[1][3], cm.matrix[2][3]);
    }

    /**
        Gets a relative position for 2 matrices

        Inverse order of getRelativePosition
    */
    static
    vec3 getRelativePositionInv(mat4 m1, mat4 m2) {
        mat4 cm = (m2 * m1.inverse).translation;
        return vec3(cm.matrix[0][3], cm.matrix[1][3], cm.matrix[2][3]);
    }

    /**
        Gets the path to the node.
    */
    final
    string getNodePath() {
        import std.array : join;
        if (nodePath_.length > 0) return nodePath_;

        string[] pathSegments;
        Node parent = this;
        while(parent !is null) {
            pathSegments = [parent.name[]] ~ pathSegments;
            parent = parent.parent;
        }
        
        nodePath_ = "/"~pathSegments.join("/");
        return nodePath_;
    }

    /**
        Gets the depth of this node
    */
    final int depth() {
        int depthV;
        Node parent = this;
        while(parent !is null) {
            depthV++;
            parent = parent.parent;
        }
        return depthV;
    }

    /**
        Removes all children from this node
    */
    final void clearChildren() {
        foreach(child; children_) {
            child.parent_ = null;
        }
        this.children_.clear();
    }

    /**
        Adds a node as a child of this node.
    */
    final void addChild(Node child) {
        child.parent = this;
    }

    /**
        Finds this node within its parent node.

        Returns:
            A positive value if this node was found,
            otherwise $(D -1).
    */
    final ptrdiff_t getIndexInParent() {
        return this.getIndexInNode(parent_);
    }

    /**
        Finds this node within the given node.

        Params:
            node = The node to look within

        Returns:
            A positive value if this node was found,
            otherwise $(D -1).
    */
    final ptrdiff_t getIndexInNode(Node node) {
        if (node) {
            foreach(i, ref child; node.children_) {
                if (child is this)
                    return i;
            }
        }
        return -1;
    }

    enum OFFSET_START = size_t.min;
    enum OFFSET_END = size_t.max;
    final void insertInto(Node node, size_t offset) @nogc {
        nodePath_ = null;
        
        // Remove ourselves from our current parent if we are
        // the child of one already.
        if (parent_ !is null) {
            parent_.children_.remove(this);
            parent_.release();
        }

        // If we want to become parentless we need to handle that
        // seperately, as null parents have no children to update
        if (node is null) {
            this.parent_ = null;
            return;
        }

        // Update our relationship with our new parent
        this.parent_ = node;
        this.parent_.retain();

        // Update position
        if (offset == OFFSET_START) {
            this.parent_.children_.insert(this, 0);
        } else if (offset == OFFSET_END || offset >= parent_.children_.length) {
            this.parent_.children_ ~= this;
        } else {
            this.parent_.children_.insert(this, offset);
        }
        if (this.puppet !is null)
            assumeNoThrowNoGC((Puppet puppet) { puppet.rescanNodes(); }, puppet);
    }

    /**
        Applies an offset to the Node's transform.

        Params:
            other = The transform to offset the current global transform by.
    */
    void offsetTransform(Transform other) @nogc {
        globalTransform = globalTransform.calcOffset(other);
        globalTransform.update();
    }

    /**
        Gets whether the node has the given parameter key.

        Params:
            key = The key to query.
        
        Returns:
            $(D true) if the node has a key of the given name,
            $(D false) otherwise.
    */
    bool hasParam(string key) @nogc {
        switch(key) {
            case "zSort":
            case "transform.t.x":
            case "transform.t.y":
            case "transform.t.z":
            case "transform.r.x":
            case "transform.r.y":
            case "transform.r.z":
            case "transform.s.x":
            case "transform.s.y":
                return true;
            default:
                return false;
        }
    }

    /**
        Gets the default value for a node parameter.

        Params:
            key =   The key to get.

        Returns:
            The default value for a given node parameter.
    */
    float getDefaultValue(string key) @nogc {
        switch(key) {
            case "zSort":
            case "transform.t.x":
            case "transform.t.y":
            case "transform.t.z":
            case "transform.r.x":
            case "transform.r.y":
            case "transform.r.z":
                return 0;
            case "transform.s.x":
            case "transform.s.y":
                return 1;
            default:
                return float();
        }
    }

    /**
        Sets a node parameter value.

        Params:
            key =   The key to set.
            value = The value to set.
        
        Returns:
            $(D true) if the operation succeded,
            $(D false) otherwise.
    */
    bool setValue(string key, float value) @nogc {
        switch(key) {
            case "zSort":
                offsetSort += value;
                return true;
            case "transform.t.x":
                transformOffset.translation.x += value;
                notifyTransformChanged();
                return true;
            case "transform.t.y":
                transformOffset.translation.y += value;
                notifyTransformChanged();
                return true;
            case "transform.t.z":
                transformOffset.translation.z += value;
                notifyTransformChanged();
                return true;
            case "transform.r.x":
                transformOffset.rotation.x += value;
                notifyTransformChanged();
                return true;
            case "transform.r.y":
                transformOffset.rotation.y += value;
                notifyTransformChanged();
                return true;
            case "transform.r.z":
                transformOffset.rotation.z += value;
                notifyTransformChanged();
                return true;
            case "transform.s.x":
                transformOffset.scale.x *= value;
                notifyTransformChanged();
                return true;
            case "transform.s.y":
                transformOffset.scale.y *= value;
                notifyTransformChanged();
                return true;
            default: return false;
        }
    }

    /**
        Scale an offset value, given an axis and a scale

        If axis is -1, apply magnitude and sign to signed properties.
        If axis is 0 or 1, apply magnitude only unless the property is
        signed and aligned with that axis.

        Note that scale adjustments are not considered aligned,
        since we consider preserving aspect ratio to be the user
        intent by default.
    */
    float scaleValue(string key, float value, int axis, float scale) @nogc {
        if (axis == -1) return value * scale;

        float newVal = abs(scale) * value;
        switch(key) {
            case "transform.r.z": // Z-rotation is XY-mirroring
                newVal = scale * value;
                break;
            case "transform.r.y": // Y-rotation is X-mirroring
            case "transform.t.x":
                if (axis == 0) newVal = scale * value;
                break;
            case "transform.r.x": // X-rotation is Y-mirroring
            case "transform.t.y":
                if (axis == 1) newVal = scale * value;
                break;
            default:
                break;
        }
        return newVal;
    }

    /**
        Gets the parameter editable value for a given key.

        Params:
            key = The key to query.
        
        Returns:
            The value of the given named node parameter.
    */
    float getValue(string key) @nogc {
        switch(key) {
            case "zSort":           return offsetSort;
            case "transform.t.x":   return transformOffset.translation.x;
            case "transform.t.y":   return transformOffset.translation.y;
            case "transform.t.z":   return transformOffset.translation.z;
            case "transform.r.x":   return transformOffset.rotation.x;
            case "transform.r.y":   return transformOffset.rotation.y;
            case "transform.r.z":   return transformOffset.rotation.z;
            case "transform.s.x":   return transformOffset.scale.x;
            case "transform.s.y":   return transformOffset.scale.y;
            default:                return 0;
        }
    }

    /**
        Deserializes this node from a DataNode.

        Params:
            object = The DataNode to deserialize from.
    */
    final void deserialize(ref DataNode object) @nogc {
        this.onDeserialize(object);
    }

    /**
        Serializes this node to a DataNode.

        Params:
            recursive = Whether to recurse through children.
    */
    final DataNode serialize(bool recursive = true) @nogc {
        auto result = DataNode.createObject();
        this.onSerialize(result, recursive);
        return result;
    }

    /**
        Serializes this node to a DataNode.

        Params:
            object =    The DataNode to serialize to.
            recursive = Whether to recurse through children.
    */
    final void serialize(ref DataNode object, bool recursive = true) @nogc {
        this.onSerialize(object, recursive);
    }

    /**
        Finalizes this node and its children.
    */
    final void finalize() @nogc {
        this.onFinalize();
    }

    /**
        Runs a pre-update cycle for this node and its enabled children.

        Params:
            drawList =  The drawlist for the active scene.

        Note:
            This is generally called by the puppet and shouldn't be called
            by you outside of circumstances where the puppet isn't
            controlling rendering.
    */
    final void preUpdate(DrawList drawList) @nogc {
        if (!enabled) return;

        transformOffset.clear();
        offsetSort = 0;

        this.onPreUpdate(drawList);
        foreach(child; children_) {
            child.preUpdate(drawList);
        }
    }

    /**
        Updates the node

        Params:
            delta =     Time since the last frame.
            drawList =  The drawlist for the active scene.

        Note:
            This is generally called by the puppet and shouldn't be called
            by you outside of circumstances where the puppet isn't
            controlling rendering.
    */
    final void update(float delta, DrawList drawList) @nogc {
        if (!enabled) return;

        this.onUpdate(delta, drawList);
        foreach(child; children) {
            child.update(delta, drawList);
        }
    }

    /**
        Update sequence run after the main update sequence.

        Params:
            drawList =  The drawlist for the active scene.

        Note:
            This is generally called by the puppet and shouldn't be called
            by you outside of circumstances where the puppet isn't
            controlling rendering.
    */
    final void postUpdate(DrawList drawList) @nogc {
        if (!enabled) return;

        this.onPostUpdate(drawList);
        foreach(child; children_) {
            child.postUpdate(drawList);
        }
    }

    /**
        Draws this node and it's subnodes
        
        Params:
            delta =     Time since the last frame.
            drawList =  The drawlist for the active scene.

        Note:
            This is generally called by the puppet and shouldn't be called
            by you outside of circumstances where the puppet isn't
            controlling rendering.
    */
    final void draw(float delta, DrawList drawList) @nogc {
        this.onDraw(delta, drawList, MaskingMode.none);
    }

    /**
        Notifies this node and its children that the transform 
        has changed.
    */
    void notifyTransformChanged() @nogc {
        recalculateTransform = true;

        foreach(child; children) {
            child.notifyTransformChanged();
        }
    }

    /**
        Gets the string representation of this object.
    */
    override
    string toString() const {
        return name[];
    }

    rect getCombinedBoundsRect(bool reupdate = false, bool countPuppet=false)() {
        vec4 combinedBounds = getCombinedBounds!(reupdate, countPuppet)();
        return rect(
            combinedBounds.x, 
            combinedBounds.y, 
            combinedBounds.z-combinedBounds.x, 
            combinedBounds.w-combinedBounds.y
        );
    }

    vec4 getInitialBoundsSize() {
        auto tr = transform;
        return vec4(tr.translation.x, tr.translation.y, tr.translation.x, tr.translation.y);
    }

    /**
        Gets the combined bounds of the node
    */
    vec4 getCombinedBounds(bool reupdate = false, bool countPuppet=false)() {
        vec4 combined = getInitialBoundsSize();
        
        // Get Bounds as drawable
        if (Drawable drawable = cast(Drawable)this) {
            if (reupdate) drawable.updateBounds();
            combined = drawable.bounds;
        }

        foreach(child; children) {
            vec4 cbounds = child.getCombinedBounds!(reupdate)();
            if (cbounds.x < combined.x) combined.x = cbounds.x;
            if (cbounds.y < combined.y) combined.y = cbounds.y;
            if (cbounds.z > combined.z) combined.z = cbounds.z;
            if (cbounds.w > combined.w) combined.w = cbounds.w;
        }

        static if (countPuppet) {
            return vec4(
                (puppet.transform.matrix*vec4(combined.xy, 0, 1)).xy,
                (puppet.transform.matrix*vec4(combined.zw, 0, 1)).xy,
            );
        } else {
            return combined;
        }
    }

    /**
        Gets whether nodes can be reparented
    */
    bool canReparent(Node to) {
        Node tmp = to;
        while(tmp !is null) {
            if (tmp.guid == this.guid) return false;
            
            // Check next up
            tmp = tmp.parent;
        }
        return true;
    }

    /** 
        Set new Parent
    */
    void reparent(Node parent, ulong pOffset) {
        if (parent !is null)
            setRelativeTo(parent);
        insertInto(parent, cast(size_t)pOffset);
    }
}
mixin Register!(Node, in_node_registry);


/**
    Finds visuals that are within the hirearchy of the given node.

    Params:
        root =              The root node to start looking from
        list =              The list to write to, the list may be resized by the
                            implementation.
        recurseDelegates =  Whether to recurse through delegate visuals.
        sort =              Whether to sort the list of visuals.
*/
void findVisuals(Node root, ref Visual[] list, bool recurseDelegates=false, bool sort = true) @nogc {
    static void findVisualsImpl(Node node, ref Visual[] list, bool recurseDelegates=false) @nogc {
        if (!node) return;
        
        if (auto visual = cast(Visual)node) {
            if (!visual.enabled)
                return;
            
            list = list.nu_resize(list.length+1);
            list[$-1] = visual;

            if (!visual.isDelegated || recurseDelegates) {
                foreach(child; node.children) {
                    findVisualsImpl(child, list, recurseDelegates);
                }
            }
        } else {

            // Non-part nodes just need to be recursed through,
            // they don't draw anything.
            foreach(child; node.children) {
                findVisualsImpl(child, list, recurseDelegates);
            }
        }
    }

    nu_freea(list);
    findVisualsImpl(root, list, recurseDelegates);
    if (sort) sortNodes(list);
}

/**
    Finds all nodes of the given type (and subtypes) in the node tree.

    Params:
        root =  The root node to start searching from.
        list =  The list to write the results to.
*/
void findNodes(T)(Node root, ref T[] list) @nogc 
if (is(T : Node)) {
    static void findNodesImpl(Node node, ref T[] list) @nogc {
        if (!node) return;
        
        if (auto found = cast(T)node) {
            list = list.nu_resize(list.length+1);
            list[$-1] = found;
        }

        // Non-part nodes just need to be recursed through,
        // they don't draw anything.
        foreach(child; node.children) {
            findNodesImpl(child, list);
        }
    }

    nu_freea(list);
    findNodesImpl(root, list);
}

/**
    Sorts a slice of visuals in-place.

    Params:
        slice = The slice to sort.
*/
void sortNodes(T)(ref T[] slice) @nogc
if (is(T : Node)) {
    import inochi2d.core.sorting : in_sort;
    import nulib.math.fixed : fixed32;

    // HACK:    nulib doesn't have a float cmp function yet,
    //          as such we convert sorting values to fixed.
    in_sort!((Visual a, Visual b) => fixed32(a.zSort).data < fixed32(b.zSort).data)(slice);
}