/*
    Inochi2D Part

    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inochi2d.core.nodes.part;
import inochi2d.core.nodes.visual;
import inochi2d.core.serde;
import inochi2d.core.math;
import inochi2d.core;
import numem;

import std.exception;
import std.algorithm.mutation : copy;
import std.math : isNaN;

public import inochi2d.core.render.state;
public import inochi2d.core.mesh;

enum NO_TEXTURE = uint.max;
enum TextureUsage : size_t {
    Albedo,
    Emissive,
    Bumpmap,
    COUNT
}

struct PartVars {
align(vec4.sizeof):
    vec3 tint;
    vec3 screenTint;
    float opacity;
    float emissionStrength;
}

/**
    Dynamic Mesh Part
*/
@TypeId("Part", 0x0101)
class Part : Visual, IDeformable {
private:
    Mesh mesh_;
    DeformedMesh deformed_;
    DeformedMesh base_;

    //
    //      PARAMETER OFFSETS
    //
    float offsetMaskThreshold = 0;
    float offsetOpacity = 1;
    float offsetEmissionStrength = 1;
    vec3 offsetTint = vec3(0);
    vec3 offsetScreenTint = vec3(0);

protected:

    /**
        The current active draw list slot for this
        drawable.
    */
    DrawListAlloc* drawListSlot;

    /**
        Serializes this node to a DataNode.

        Params:
            object =    The DataNode to serialize to.
            recursive = Whether to recurse through children.
    */
    override
    void onSerialize(ref DataNode object, bool recursive = true) {
        super.onSerialize(object, recursive);

        MeshData data = MeshData(mesh_);
        object["mesh"] = data.serialize();
        object["textures"] = DataNode.createArray();
        foreach(ref texture; textures) {
            if (texture) {
                ptrdiff_t index = puppet.getTextureSlotIndexFor(texture);
                object["textures"].array ~= DataNode(index >= 0 ? index : NO_TEXTURE);
            } else {
                object["textures"].array ~= DataNode(NO_TEXTURE);
            }
        }

        object["blend_mode"] = cast(uint)blendingMode;
        object["tint"] = tint.serialize();
        object["screenTint"] = screenTint.serialize();
        object["emissionStrength"] = emissionStrength;
        object["masks"] = masks.serialize();
        object["opacity"] = opacity;
    }

    /**
        Deserializes this node from a DataNode.

        Params:
            object = The DataNode to deserialize from.
    */
    override
    void onDeserialize(ref DataNode object) {
        super.onDeserialize(object);

        this.deformed_ = nogc_new!DeformedMesh();
        this.base_ = nogc_new!DeformedMesh();
        this.mesh = Mesh.fromMeshData(object.tryGet!MeshData("mesh"));
        if ("textures" in object && object["textures"].isArray()) {
            foreach(i, ref DataNode element; object["textures"].array) {

                uint textureId = element.tryGet!uint(NO_TEXTURE);
                if (textureId == NO_TEXTURE) continue;

                // TODO: Abstract this to properly handle refcounts.
                this.textures[i] = puppet.textureCache.get(textureId);
                if (this.textures[i])
                    this.textures[i].retain();
            }
        }
        
        object.tryGetRef(opacity, "opacity");
        object.tryGetRef(tint, "tint");
        object.tryGetRef(screenTint, "screenTint");
        object.tryGetRef(tint, "tint");
        object.tryGetRef(emissionStrength, "emissionStrength");
        
        if ("blend_mode" in object && object["blend_mode"].isNumber)
            blendingMode = cast(BlendMode)object.tryGet!uint("blend_mode", blendingMode.normal);
        else
            blendingMode = object.tryGet!string("blend_mode", "Normal").toBlendMode();
    }

    /**
        Called during the early update phase of a new frame.
        
        Params:
            drawList =  The drawlist for the active scene.
    */
    override
    void onPreUpdate(DrawList drawList) {
        offsetMaskThreshold = 0;
        offsetOpacity = 1;
        offsetTint = vec3(1, 1, 1);
        offsetScreenTint = vec3(0, 0, 0);
        offsetEmissionStrength = 1;

        super.onPreUpdate(drawList);
        this.resetDeform();
    }

    /**
        Called during the update phase of a new frame.
        
        Params:
            delta =     Time since the last frame.
            drawList =  The drawlist for the active scene.
    */
    override
    void onUpdate(float delta, DrawList drawList) {
        super.onUpdate(delta, drawList);
        deformed_.pushMatrix(transform.matrix);
    }

    /**
        Called during the late update phase of a new frame.
        
        Params:
            drawList =  The drawlist for the active scene.
    */
    override
    void onPostUpdate(DrawList drawList) {
        super.onPostUpdate(drawList);
        this.drawListSlot = drawList.allocate(deformed_.vertices, deformed_.indices);
    }

    /**
        Called when the node is to be redrawn.
        
        Params:
            delta =     Time since the last frame.
            drawList =  The drawlist for the active scene.
            mode =      The masking mode to draw with.
    */
    override
    void onDraw(float delta, DrawList drawList, MaskingMode mode) {
        if (mode >= MaskingMode.mask) {
            drawList.setMesh(drawListSlot);
            drawList.setDrawState(DrawState.defineMask);
            drawList.setSources(textures);
            drawList.setMasking(mode);
            drawList.next();
            return;
        }

        if (!renderEnabled)
            return;

        PartVars vars = PartVars(
            tint*offsetTint,
            screenTint*offsetScreenTint,
            opacity*offsetOpacity,
            emissionStrength*offsetEmissionStrength
        );
        
        if (masks.length > 0) {
            foreach(ref mask; masks) {
                if (mask.maskSrc)
                    mask.maskSrc.onDraw(delta, drawList, mask.mode);
            }

            drawList.setMesh(drawListSlot);
            drawList.setDrawState(DrawState.maskedDraw);
            drawList.setVariables!PartVars(nid, vars);
            drawList.setBlending(blendingMode);
            drawList.setSources(textures);
            drawList.next();
            return;
        }

        drawList.setMesh(drawListSlot);
        drawList.setSources(textures);
        drawList.setBlending(blendingMode);
        drawList.setVariables!PartVars(nid, vars);
        drawList.next();
    }

public:

    /**
        The mesh of the part..
    */
    final @property Mesh mesh() @nogc => mesh_;
    final @property void mesh(Mesh value) @nogc {
        if (value is mesh_)
            return;
        
        if (mesh_)
            mesh_.release();

        this.mesh_ = value.retained();
        this.deformed_.parent = value;
        this.base_.parent = value;
    }

    /**
        Local matrix of the deformable object.
    */
    override @property Transform baseTransform() @nogc => transform!true;

    /**
        World matrix of the deformable object.
    */
    override @property Transform worldTransform() @nogc => transform!false;

    /**
        The base position of the deformable's points.
    */
    @property const(vec2)[] basePoints() => base_.points;

    /**
        The points which may be deformed by the deformer.
    */
    override @property vec2[] deformPoints() => deformed_.points;

    /**
        List of textures this part can use

        TODO: use more than texture 0
    */
    Texture[IN_MAX_ATTACHMENTS] textures;

    /**
        Blending mode
    */
    BlendMode blendingMode = BlendMode.normal;

    /**
        Opacity of the mesh
    */
    float opacity = 1;

    /**
        Strength of emission
    */
    float emissionStrength = 1;

    /**
        Multiplicative tint color
    */
    vec3 tint = vec3(1, 1, 1);

    /**
        Screen tint color
    */
    vec3 screenTint = vec3(0, 0, 0);

    /**
        Gets the active texture
    */
    Texture activeTexture() {
        return textures[0];
    }

    /// Destructor
    ~this() {
        mesh_.release();
        nogc_delete(deformed_);
        foreach(texture; textures) {
            if (texture)
                texture.release();
        }
    }

    /**
        Constructs a new part
    */
    this(Node parent = null) {
        super(parent);
    }

    /**
        Constructs a new part
    */
    this(MeshData data, Node parent = null) {
        this(data, inNewGUID(), parent);
    }

    /**
        Constructs a new part
    */
    this(MeshData data, GUID guid, Node parent = null) {
        super(guid, parent);
        
        this.deformed_ = nogc_new!DeformedMesh();
        this.base_ = nogc_new!DeformedMesh();
        this.mesh = Mesh.fromMeshData(data);
    }

    /**
        Constructs a new part
    */
    this(MeshData data, Texture[] textures, Node parent = null) {
        this(data, textures, inNewGUID(), parent);
    }

    /**
        Constructs a new part
    */
    this(MeshData data, Texture[] textures, GUID guid, Node parent = null) {
        this(data, guid, parent);
        foreach(i; 0..TextureUsage.COUNT) {
            if (i >= textures.length) break;
            this.textures[i] = textures[i];
        }
    }

    /**
        Resets the deformation for the IDeformable.
    */
    override
    void resetDeform() {
        deformed_.reset();
        
        base_.reset();
        base_.pushMatrix(baseTransform.matrix);
    }

    /**
        Deforms the IDeformable.

        Params:
            deformed =  The deformation delta.
            absolute =  Whether the deformation is absolute,
                        replacing the original deformation.
    */
    override
    void deform(vec2[] deformed, bool absolute = false) {
        deformed_.deform(deformed);
    }
    
    /**
        Deforms a single vertex in the IDeformable

        Params:
            offset =    The offset into the point list to deform.
            deform =    The deformation delta.
            absolute =  Whether the deformation is absolute,
                        replacing the original deformation.
    */
    override void deform(size_t offset, vec2 deform, bool absolute = false) {
        deformed_.deform(offset, deform);
    }

    override
    bool hasParam(string key) {
        if (super.hasParam(key)) return true;

        switch(key) {
            case "opacity":
            case "tint.r":
            case "tint.g":
            case "tint.b":
            case "screenTint.r":
            case "screenTint.g":
            case "screenTint.b":
            case "emissionStrength":
                return true;
            default:
                return false;
        }
    }

    override
    float getDefaultValue(string key) {
        // Skip our list of our parent already handled it
        float def = super.getDefaultValue(key);
        if (!isNaN(def)) return def;

        switch(key) {
            case "alphaThreshold":
                return 0;
            case "opacity":
            case "tint.r":
            case "tint.g":
            case "tint.b":
                return 1;
            case "screenTint.r":
            case "screenTint.g":
            case "screenTint.b":
                return 0;
            case "emissionStrength":
                return 1;
            default: return float();
        }
    }

    override
    bool setValue(string key, float value) {
        
        // Skip our list of our parent already handled it
        if (super.setValue(key, value)) return true;

        switch(key) {
            case "opacity":
                offsetOpacity *= value;
                return true;
            case "tint.r":
                offsetTint.x *= value;
                return true;
            case "tint.g":
                offsetTint.y *= value;
                return true;
            case "tint.b":
                offsetTint.z *= value;
                return true;
            case "screenTint.r":
                offsetScreenTint.x += value;
                return true;
            case "screenTint.g":
                offsetScreenTint.y += value;
                return true;
            case "screenTint.b":
                offsetScreenTint.z += value;
                return true;
            case "emissionStrength":
                offsetEmissionStrength += value;
                return true;
            default: return false;
        }
    }
    
    override
    float getValue(string key) {
        switch(key) {
            case "opacity":             return offsetOpacity;
            case "tint.r":              return offsetTint.x;
            case "tint.g":              return offsetTint.y;
            case "tint.b":              return offsetTint.z;
            case "screenTint.r":        return offsetScreenTint.x;
            case "screenTint.g":        return offsetScreenTint.y;
            case "screenTint.b":        return offsetScreenTint.z;
            case "emissionStrength":    return offsetEmissionStrength;
            default:                    return super.getValue(key);
        }
    }

    /**
        Applies an offset to the Node's transform.

        Params:
            other = The transform to offset the current global transform by.
    */
    override
    void offsetTransform(Transform other) @nogc {
        globalTransform = globalTransform.calcOffset(other);
        globalTransform.update();
    }
}
mixin Register!(Part, in_node_registry);
