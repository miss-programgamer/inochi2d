module inochi2d.godot.puppet;
import godot.resource_format_loader;
import godot.resource_loader;
import godot.resource;
import godot.node2d;
import godot;

import inochi2d.puppet;
import numem;

/**
    An Inochi2D Puppet.
*/
class Inochi2DPuppet : Node2D {
private:
@nogc:
    Inochi2DPuppetResource resource_;
    Puppet puppet_;

protected:

public:

    /// Destructor
    ~this() {
        gd_delete(resource_);
    }

    /**
        The puppet resource
    */
    @gd_export final @property Inochi2DPuppetResource puppet() => resource_;
    @gd_export final @property void puppet(Inochi2DPuppetResource value) {
        if (puppet_)
            nogc_delete(puppet_);

        this.resource_ = gde_refswap(resource_, value);
        if (resource_) {
            this.puppet_ = resource_.realize();
        }
    }
}
mixin GodotClass!Inochi2DPuppet;

/**
    A resource for an Inochi2D Puppet
*/
class Inochi2DPuppetResource : Resource {
private:
@nogc:
    PackedArray!ubyte data_;

public:

    /**
        Data of the puppet.
    */
    final @property PackedArray!ubyte data() => data_;

    /**
        Size of the model file in bytes.
    */
    @gd_export_custom(PROPERTY_HINT_ONESHOT, "", PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY)
    final @property uint fileSize() => cast(uint)data_.size;

    /// Constructor
    this() { }

    /**
        Loads an Inochi2D puppet from file.
    */
    @gd_hide bool loadFile(String path) {
        import godot.file_access : FileAccess;
        import core.stdc.stdio : printf;

        // Load data from file.
        this.data_ = FileAccess.getFileAsBytes(path);
        return data_.ptrw !is null;
    }

    /**
        Realizes an instance of the puppet from the resource.
    */
    @gd_hide Puppet realize() {
        import nulib.io.stream : MemoryStream;

        // Load puppet into stream
        auto mstream = nogc_new!MemoryStream(data_[]);
        scope(exit) {
            // Yoink the ownership so we don't free the array.
            mstream.take();
            nogc_delete(mstream);
        }

        // Parse puppet
        auto puppet = Puppet.fromStream(mstream);
        if (!puppet.isOK) {
            printError(puppet.error);
            return null;
        }

        // Success!
        return puppet.get();
    }
}
mixin GodotClass!Inochi2DPuppetResource;

/**
    Puppet resource loader.
*/
@gd_editor
class Inochi2DPuppetResourceFormatLoader : ResourceFormatLoader {
private:
@nogc:
    __gshared Inochi2DPuppetResourceFormatLoader __instance;

public:

    /**
        Gets the list of extensions for files this loader is able to read.
    */
    override PackedArray!String getRecognizedExtensions_() {
        PackedArray!String str;
        str.resize(2);
        str.ptrw[0] = String("inp");
        str.ptrw[1] = String("inx");
        return str;
    }

    override bool handlesType_(StringName type) {
        return type == "Inochi2DPuppetResource";
    }

    override String getResourceType_(String path) {
        if (path.endsWith(".inp") || path.endsWith(".inx"))
            return String("Inochi2DPuppetResource");
        return String.init;
    }

    override Variant load_(String path, String originalpath, bool usesubthreads, int cachemode) {
        if (Inochi2DPuppetResource res = gd_new!Inochi2DPuppetResource) {
            if (res.loadFile(path))
                return Variant(gde_ref(res));
        }
        return Variant.init;
    }

    /**
        Special callback
    */
    static void __gde_postregistration() {
        __instance = gd_new!Inochi2DPuppetResourceFormatLoader();
        ResourceLoader.instance.addResourceFormatLoader(__instance, true);
    }

    /**
        Special callback
    */
    static void __gde_preunregistration() {
        ResourceLoader.instance.removeResourceFormatLoader(__instance);
        __instance = null;
    }
    
}
mixin GodotClass!Inochi2DPuppetResourceFormatLoader;