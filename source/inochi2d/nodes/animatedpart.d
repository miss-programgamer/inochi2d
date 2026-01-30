module inochi2d.nodes.animatedpart;
import inochi2d.nodes.part;
import inochi2d.nodes;
import inochi2d.core;


/**
    Parts which contain spritesheet animation
*/
@TypeId("AnimatedPart", 0x0201)
class AnimatedPart : Part {

}
mixin Register!(AnimatedPart, in_node_registry);