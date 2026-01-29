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
struct prop_expose { string name; } // @suppress(dscanner.style.phobos_naming_convention)

/**
    Implements the IPropertyOwner interface.
*/
mixin template IPropertyOwnerImpl() {
    import inochi2d.core.property : prop_expose;
    import numem.core.traits;
    import numem.core.meta;

    static assert(is(typeof(this) : IPropertyOwner), T.stringof ~ " does not derive from IPropertyOwner");
    
    // Gets all exposed properties.
    template getProperties(alias T) {
        template getProperty(T, alias member) {
            static if (hasUDA!(__traits(getMember, T, member), prop_expose))
                enum getProperty = member;
            else
                enum getProperty = null;
        }

        alias getProperties = AliasSeq!();
        static foreach(member; __traits(allMembers, typeof(T))) {
            static if (getProperty!(typeof(T), member)) {
                getProperties = AliasSeq!(getProperties, member);
            }
        }
    }

    // Gets the name of a property.
    template getPropertyName(alias prop) {
        static if (getUDAs!(prop, prop_expose)[0].name)
            enum getPropertyName = getUDAs!(prop, prop_expose)[0].name;
        else
            enum getPropertyName = __traits(identifier, prop);
    }

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
            switch(key) {
                static foreach(property; properties) {
                    case getPropertyName!(__traits(getMember, this, property)):
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
            switch(key) {
                static foreach(property; properties) {
                    case getPropertyName!(__traits(getMember, this, property)):
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
            switch(key) {
                static foreach(property; properties) {
                    case getPropertyName!(__traits(getMember, this, property)):
                        return __traits(getMember, this, property);
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
            switch(key) {
                static foreach(property; properties) {
                    case getPropertyName!(__traits(getMember, this, property)):
                        return __traits(getMember, this, property);
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
            switch(key) {
                static foreach(property; properties) {
                    case getPropertyName!(__traits(getMember, this, property)):
                        __traits(getMember, this, property) = value;
                        return;
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
            switch(key) {
                static foreach(property; properties) {
                    case getPropertyName!(__traits(getMember, this, property)):
                        __traits(getMember, this, property) = value;
                        return;
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
            switch(key) {
                static foreach(property; properties) {
                    case getPropertyName!(__traits(getMember, this, property)):
                        __traits(getMember, this, property) = __traits(getMember, this, property).init;
                        return;
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
            switch(key) {
                static foreach(property; properties) {
                    case getPropertyName!(__traits(getMember, this, property)):
                        __traits(getMember, this, property) = __traits(getMember, this, property).init;
                        return;
                }

                default:
                    return;
            }
        }

    }
}