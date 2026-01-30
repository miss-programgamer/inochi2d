/*
    Inochi2D Composite Node

    Copyright © 2022, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.

    Authors: Hoshino Lina
*/
module inochi2d.nodes.drivers;
import inochi2d.nodes;
import inochi2d.param;
import inochi2d.core;

public import inochi2d.nodes.drivers.simplephysics;

/**
    Driver abstract node type
*/
@TypeId("Driver", 0x00000003)
@TypeIdAbstract
abstract class Driver : Node {
protected:
@nogc:
    
    this() { }

    /**
        Constructs a new Driver node
    */
    this(GUID guid, Node parent = null) {
        super(guid, parent);
    }

public:

    /**
        The affected parameters of the driver.
    */
    @property Parameter[] affectedParameters() => null;

    /**
        Gets whether the given parameter is affected by
        this driver.

        Params:
            param = The parameter to query.
        
        Returns:
            $(D true) if the parameter is affected by 
            the driver, $(D false) otherwise.
    */
    final
    bool affectsParameter(ref Parameter param) {
        foreach(ref Parameter p; this.affectedParameters) {
            if (p.guid == param.guid)
                return true;
        } 
        return false;
    }

    /**
        Updates the state of the driver.

        Params:
            delta = Time since the last frame.
    */
    abstract void updateDriver(float delta);

    /**
        Resets the driver's state.
    */
    abstract void reset();
}
mixin Register!(Driver, in_node_registry);
