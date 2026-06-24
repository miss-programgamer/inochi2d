/**
    Bone nodes.

    Bones are used to make up one or more skeletons which can be transformed
    by parameters or affected by physics.

    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inochi2d.nodes.bone.modifier;
import inochi2d.nodes;

/**
    A modifier that affect one given bone and potentially any
    child bones in the skeleton chain.
*/
@TypeIdAbstract
@TypeId("BoneModifier", 0x0011)
abstract class BoneModifier : Node {

}
mixin Register!(BoneModifier, in_node_registry);