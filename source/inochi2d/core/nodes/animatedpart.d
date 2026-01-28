module inochi2d.core.nodes.animatedpart;
import inochi2d.core.nodes.part;
import inochi2d.core;
import inochi2d.core.math;


/**
    Parts which contain spritesheet animation
*/
@TypeId("AnimatedPart", 0x0201)
class AnimatedPart : Part {

}
mixin Register!(AnimatedPart, in_node_registry);