/**
    Inochi2D Properties

    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inochi2d.core.property;
import numem.core.meta;
import numem.core.traits;

/**
    A type which contains properties.
*/
interface IPropertyOwner {
@nogc nothrow:

    /**
        Gets whether a property with the given name exists
        in the property type.

        Params:
            key = The name of the property.
        
        Returns:
            $(D true) if the property exists,
            $(D false) otherwise.
    */
    bool hasProperty(string key);

    /**
        Gets the value of a given property.

        Params:
            key = The name of the property.
        
        Returns:
            The floating point value of the property.
    */
    float getProperty(string key);

    /**
        Gets the default value of a given property.

        Params:
            key = The name of the property.
        
        Returns:
            The default value of the property.
    */
    float getPropertyDefault(string key);

    /**
        Sets the value of the property.

        Params:
            key =   The name of the property.
            value = The value to set the property to.
    */
    void setProperty(string key, float value);

    /**
        Clears the given property.

        Params:
            key =   The name of the property.
    */
    void clearProperty(string key);
}

/**
    Exposes a given property.
*/
struct prop_expose; // @suppress(dscanner.style.phobos_naming_convention)

/**
    Sets the name for a property.
*/
struct prop_name { string name; } // @suppress(dscanner.style.phobos_naming_convention)

/**
    Sets the default value for a property.
*/
struct prop_default(T) { T value; } // @suppress(dscanner.style.phobos_naming_convention)

/**
    Gets all the directly exposed properties for the given symbol.

    Params:
        T = The symbol to query properties for.
*/
template getProperties(alias T) {
    private template getProperty(T, alias member) {

        alias overloads = AliasSeq!(__traits(getOverloads, T, member));
        static if (overloads.length > 0) {
            static if (hasUDA!(overloads[0], prop_expose))
                enum getProperty = member;
            else
                enum getProperty = null;
        } else {
            static if (hasUDA!(__traits(getMember, T, member), prop_expose))
                enum getProperty = member;
            else
                enum getProperty = null;
        }
    }

    private template staticIndexOf(alias A, args...) {
        static foreach (idx, arg; args) {
            static if (!is(typeof(staticIndexOf) == ptrdiff_t) && __traits(isSame, A, arg)) {
                enum ptrdiff_t staticIndexOf = idx;
            }
        }
        static if (!is(typeof(staticIndexOf) == ptrdiff_t))
            enum ptrdiff_t staticIndexOf = -1;
    }

    private template appendUnique(items...) {
        alias head = items[0 .. $ - 1];
        static if (staticIndexOf!(items[$ - 1], head) >= 0)
            alias appendUnique = head;
        else
            alias appendUnique = items;
    }

    template filterDuplicates(args...)
    {
        alias filterDuplicates = AliasSeq!();
        static foreach (arg; args)
            filterDuplicates = appendUnique!(filterDuplicates, arg);
    }

    // Scan through all public members and get whether they're exposed properties.
    alias getProperties = AliasSeq!();
    static if (is(T)) {
        static foreach (member; __traits(allMembers, T)) {
            static if (getProperty!(T, member)) {
                getProperties = AliasSeq!(getProperties, member);
            }
        }
    } else {
        static foreach (member; __traits(allMembers, typeof(T))) {
            static if (getProperty!(typeof(T), member)) {
                getProperties = AliasSeq!(getProperties, member);
            }
        }
    }

    // Filter out all duplicates.
    getProperties = filterDuplicates!getProperties;
}

/**
    Implements the IPropertyOwner interface.
*/
mixin template IPropertyOwnerImpl() {
    static assert(is(typeof(this) : IPropertyOwner), T.stringof ~ " does not derive from IPropertyOwner");

    import inochi2d.core.property : prop_expose;
    import numem.core.traits;
    import numem.core.meta;

    // Gets the name of a property.
    private template getPropertyName(T, alias prop) {
        alias overloads = AliasSeq!(__traits(getOverloads, T, prop));
        static if (overloads.length > 0) {
            static if (hasUDA!(overloads[0], prop_name)) {
                enum getPropertyName = getUDAs!(overloads[0], prop_name)[0].name;
            } else {
                enum getPropertyName = __traits(identifier, overloads[0]);
            }
        } else {
            static if (hasUDA!(__traits(getMember, T, prop), prop_name)) {
                enum getPropertyName = getUDAs!(__traits(getMember, T, prop), prop_name)[0].name;
            } else {
                enum getPropertyName = __traits(identifier, __traits(getMember, T, prop));
            }
        }
    }
    // Gets the default value of a property.
    private template getPropertyDefault(T, alias prop) {

        alias overloads = AliasSeq!(__traits(getOverloads, T, prop));
        static if (overloads.length > 0) {
            static foreach(overload; overloads) {
                static if (!is(ReturnType!overload == void)) {
                    static if (hasUDA!(overload, prop_default)) {
                        enum getPropertyDefault = getUDAs!(overload, prop_default)[0].value;
                    } else {
                        enum getPropertyDefault = ReturnType!(overload).init;
                    }
                }
            }
        } else {
            static if (hasUDA!(__traits(getMember, T, prop), prop_default)) {
                enum getPropertyDefault = getUDAs!(__traits(getMember, T, prop), prop_default)[0].value;
            } else {
                enum getPropertyDefault = __traits(getMember, new T(), prop);
            }
        }
    }

    // Gets whether the given alias 
    private enum isPropertyFunction(alias prop) = isSomeFunction!(typeof(prop));

    /// Gets whether the given property has a getter.
    private enum hasGetter(T, alias prop) = is(typeof(() { auto p = __traits(getMember, T.init, prop); }));

    /// Gets whether the given property has a setter.
    private enum hasSetter(T, alias prop) = is(typeof(() { __traits(getMember, T.init, prop) = typeof(__traits(getMember, T, prop)).init; }));

    /// Gets whether the given property has a default.
    private enum hasDefault(T, alias prop) = is(typeof(() { __traits(getMember, T.init, prop) = __traits(getMember, T, prop).init; }));

    //
    //      bool hasProperty(string key) @nogc nothrow
    //
    static if (is(typeof(super.hasProperty))) {

        /**
            Gets whether the object has the given property.

            Params:
                key = The key to query.
            
            Returns:
                $(D true) if the node has a key of the given name,
                $(D false) otherwise.
        */
        override
        bool hasProperty(string key) @nogc nothrow {
            alias properties = getProperties!(this);
            switch (key) {
                static foreach (property; properties) {
                    case getPropertyName!(typeof(this), property):
                            return true;
                }

            default:
                return super.hasProperty(key);
            }
        }
    } else {

        /**
            Gets whether the object has the given property.

            Params:
                key = The key to query.
            
            Returns:
                $(D true) if the node has a key of the given name,
                $(D false) otherwise.
        */
        bool hasProperty(string key) @nogc nothrow {
            alias properties = getProperties!(this);
            switch (key) {
                static foreach (property; properties) {
                    case getPropertyName!(typeof(this), property):
                        return true;
                }

            default:
                return false;
            }
        }
    }

    //
    //          float getProperty(string key) @nogc nothrow
    //
    static if (is(typeof(super.getProperty))) {

        /**
            Gets the value of a given property.

            Params:
                key = The name of the property.
            
            Returns:
                The floating point value of the property.
        */
        override
        float getProperty(string key) @nogc nothrow {
            alias properties = getProperties!(this);
            switch (key) {
                static foreach (property; properties) {
                    static if (hasGetter!(typeof(this), property)) {
                        case getPropertyName!(typeof(this), property):
                            return __traits(getMember, this, property);
                    }
                }

            default:
                return super.getProperty(key);
            }
        }

    } else {

        /**
            Gets the value of a given property.

            Params:
                key = The name of the property.
            
            Returns:
                The floating point value of the property.
        */
        float getProperty(string key) @nogc nothrow {
            alias properties = getProperties!(this);
            switch (key) {
                static foreach (property; properties) {
                    static if (hasGetter!(typeof(this), property)) {
                        case getPropertyName!(typeof(this), property):
                            return __traits(getMember, this, property);
                    }
                }

            default:
                return float.init;
            }
        }

    }

    //
    //          float getPropertyDefault(string key) @nogc nothrow
    //
    static if (is(typeof(super.getPropertyDefault))) {

        /**
            Gets the value of a given property.

            Params:
                key = The name of the property.
            
            Returns:
                The floating point value of the property.
        */
        override
        float getPropertyDefault(string key) @nogc nothrow {
            alias properties = getProperties!(this);
            switch (key) {
                static foreach (property; properties) {
                    static if (!is(typeof(getPropertyDefault!(typeof(this), property)) == void)) {
                        case getPropertyName!(typeof(this), property):
                            return cast(float)getPropertyDefault!(typeof(this), property);
                    }
                }

            default:
                return super.getPropertyDefault(key);
            }
        }

    } else {

        /**
            Gets the value of a given property.

            Params:
                key = The name of the property.
            
            Returns:
                The floating point value of the property.
        */
        float getPropertyDefault(string key) @nogc nothrow {
            alias properties = getProperties!(this);
            switch (key) {
                static foreach (property; properties) {
                    static if (!is(typeof(getPropertyDefault!(typeof(this), property)) == void)) {
                        case getPropertyName!(typeof(this), property):
                            return cast(float)getPropertyDefault!(typeof(this), property);
                    }
                }

            default:
                return float.init;
            }
        }

    }

    //
    //          void setProperty(string key, float value) @nogc nothrow
    //
    static if (is(typeof(super.setProperty))) {

        /**
            Sets the value of the property.

            Params:
                key =   The name of the property.
                value = The value to set the property to.
        */
        override
        void setProperty(string key, float value) @nogc nothrow {
            alias properties = getProperties!(this);
            switch (key) {
                static foreach (property; properties) {
                    static if (hasSetter!(typeof(this), property)) {
                        case getPropertyName!(typeof(this), property):
                            __traits(getMember, this, property) = cast(typeof(__traits(getMember, this, property)))value;
                            return;
                    }
                }

            default:
                super.setProperty(key, value);
                return;
            }
        }

    } else {

        /**
            Sets the value of the property.

            Params:
                key =   The name of the property.
                value = The value to set the property to.
        */
        void setProperty(string key, float value) @nogc nothrow {
            alias properties = getProperties!(this);
            switch (key) {
                static foreach (property; properties) {
                    static if (hasSetter!(typeof(this), property)) {
                        case getPropertyName!(typeof(this), property):
                            __traits(getMember, this, property) = cast(typeof(__traits(getMember, this, property)))value;
                            return;
                    }
                }

            default:
                return;
            }
        }

    }

    //
    //          void clearProperty(string key) @nogc nothrow
    //
    static if (is(typeof(super.clearProperty))) {

        /**
            Clears the given property.

            Params:
                key =   The name of the property.
        */
        override
        void clearProperty(string key) @nogc nothrow {
            alias properties = getProperties!(this);
            switch (key) {
                static foreach (property; properties) {
                    static if (!is(typeof(getPropertyDefault!(typeof(this), property)) == void)) {
                        case getPropertyName!(typeof(this), property):
                            __traits(getMember, this, property) = getPropertyDefault!(typeof(this), property);
                            return;
                    }
                }

            default:
                super.clearProperty(key);
                return;
            }
        }

    } else {

        /**
            Clears the given property.

            Params:
                key =   The name of the property.
        */
        void clearProperty(string key) @nogc nothrow {
            alias properties = getProperties!(this);
            switch (key) {
                static foreach (property; properties) {
                    static if (!is(typeof(getPropertyDefault!(typeof(this), property)) == void)) {
                        case getPropertyName!(typeof(this), property):
                            __traits(getMember, this, property) = getPropertyDefault!(typeof(this), property);
                            return;
                    }
                }

            default:
                return;
            }
        }

    }
}

@("IPropertyOwner")
unittest {
    static class Test : IPropertyOwner {
    @nogc:
        @prop_expose int a = 24;
        @prop_expose @prop_name("nb") int b;

        // @prop_expose @property int c() nothrow => a;
        @prop_expose @property void c(int v) nothrow { a = v; }

        mixin IPropertyOwnerImpl;
    }

    Test t = new Test();
    assert(t.hasProperty("a"));
    assert(t.hasProperty("nb"));
    assert(t.hasProperty("c"));

    t.setProperty("a", 1);
    assert(t.getProperty("a") == 1);
    assert(t.getProperty("c") != 0);

    t.clearProperty("a");
    assert(t.getProperty("a") == 24);
}