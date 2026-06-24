//
//          GLOBAL INOCHI2D LIBRARY INSTANCE.
//
var __inochi2d = {
    module: null,
    instance: null,
    nu_malloc: null,
    nu_free: null,
    __import_object: {
        env: {
            STACKTOP: 0,
            STACK_MAX:65536,
            abortStackOverflow: function(val) { throw new Error("stackoverfow"); },
            memory: new WebAssembly.Memory( { initial: 256 } ),
            table: new WebAssembly.Table( { initial:0, maximum:0, element: "anyfunc" } ),
            memoryBase:0,
            tableBase:0
        },
        wasi_snapshot_preview1: {
            args_get() { return 0; },
            args_sizes_get() { return 0; },
            path_open() { return 0; },
            fd_close() { return 0; },
            fd_seek() { return 0; },
            fd_read() { return 0; },
            fd_write() { return 0; },
            fd_fdstat_get() { return 0; },
            fd_fdstat_set_flags() { return 0; },
            fd_prestat_get() { return 0; },
            fd_prestat_dir_name() { return 0; },
            proc_exit() { return 0; },
        }
    }
};

/**
    Initializes Inochi2D with an optional module path.

    If none are selected, it is assumed that the inochi2d wasm
    module is placed next to the wrapper JS file.    
*/
async function in_init(url = "inochi2d.wasm") {
    try {
        let result = await WebAssembly.instantiateStreaming(fetch(url), __inochi2d.__import_object);
        __inochi2d.module = result.module;
        __inochi2d.instance = result.instance;
        __inochi2d.instance.exports._start();
        __inochi2d.nu_malloc = __inochi2d.instance.exports.nu_malloc;
        __inochi2d.nu_free = __inochi2d.instance.exports.nu_free;
    } catch(error) {
        throw error;
    }
}

/**
    An Inochi2D puppet.    
*/
class InPuppet {
    #ptr;
    #textureCache;
    #drawlist;

    // Destructor
    [Symbol.dispose]() {
        __inochi2d.instance.exports.in_puppet_free(this.#ptr);
    }

    /**
        Constructs a new puppet from a given URL.
    */
    constructor(url) {
        try {
            const data = fetch(url)
            .then((response) => response.bytes())
            .then((data) => {
                let wptr = __inochi2d.nu_malloc(data.byteLength);
                let wasm_view = new DataView(__inochi2d.instance.exports.memory.buffer);

                for (let i = 0; i < data.byteLength; i++) {
                    wasm_view.setUint8(wptr+i, data[i]);
                }
                console.log(wptr);

                this.#ptr = __inochi2d.instance.exports.in_puppet_load_from_memory(wptr, data.byteLength);
                __inochi2d.nu_free(wptr);
            });
        } catch(error) {
            throw error;
        }
    }

    /**
        The name of the puppet.
    */
    get name() { return ""; }

    /**
        Whether physics is enabled.
    */
    get physicsEnabled() { return __inochi2d.instance.exports.in_puppet_get_physics_enabled(this.#ptr) != 0; }
    set physicsEnabled(value) { __inochi2d.instance.exports.in_puppet_set_physics_enabled(this.#ptr, value); }

    /**
        The pixels-per-meter mapping for physics
    */
    get pixelsPerMeter() { return __inochi2d.instance.exports.in_puppet_get_pixels_per_meter(this.#ptr); }
    set pixelsPerMeter(value) { __inochi2d.instance.exports.in_puppet_set_pixels_per_meter(this.#ptr, value); }

    /**
        The gravity constant for the puppet, in meters-per-second.
    */
    get gravity() { return __inochi2d.instance.exports.in_puppet_get_gravity(this.#ptr); }
    set gravity(value) { __inochi2d.instance.exports.in_puppet_set_gravity(this.#ptr, value); }

    /**
        Updates the puppet.
    */
    update(delta) {
        __inochi2d.instance.exports.in_puppet_update(this.#ptr, delta);
    }

    /**
        Draws the puppet.
    */
    draw(delta) {
        __inochi2d.instance.exports.in_puppet_draw(this.#ptr, delta);
    }
}