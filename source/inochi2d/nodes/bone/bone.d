/**
    Bone nodes

    Copyright © 2020, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inochi2d.nodes.bone.bone;
import inochi2d.nodes;

/**
    A bone, bones are used to build skeletal hirearchies that deform
    other nodes via the use of bone weights.
*/
@TypeIdAbstract
@TypeId("Bone", 0x0010)
class Bone : Node {

}
mixin Register!(Bone, in_node_registry);