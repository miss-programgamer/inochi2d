/**
    INP 1 Format Writer

    Copyright © 2020-2025, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inp.format.inp1.writer;
import inp.format.json.writer;
import inp.format.node;
import inp.format.inp1;
import nulib.io.stream;
import nulib.io.stream.rw;
import nulib.math;
import numem;

import inp.format : 
    INP_TAG_PAYLOAD, 
    INP_TAG_TEXTURES, 
    INP_TAG_VENDOR;

@nogc:

/**
    Write the contents of a $(D DataNode) into the INP1 File.

    Params:
        stream =    The stream to write to.
        node =      A DataNode object following the INP structure.
*/
void writeINP1(Stream stream, ref DataNode node) {
    scope  StreamWriter writer = new StreamWriter(stream);

    if (INP_TAG_PAYLOAD in node) {
        writer.writeUTF8(INP1_MAGIC);

        ubyte[] payload = node[INP1_MAGIC].makeJsonPayload();
        writer.writeBE!uint(cast(uint)payload.length);
        stream.write(payload);

        nu_freea(payload);
    }

    if (INP_TAG_TEXTURES in node) {
        writer.writeUTF8(INP_TAG_TEXTURES);
        writer.writeBE!uint(cast(uint)node[INP_TAG_TEXTURES].length);
        foreach(ref value; node[INP_TAG_TEXTURES].array) {
            writer.writeBE!uint(cast(uint)value["data"].blob.length);
            writer.writeBE!ubyte(value["encoding"].tryCoerce!ubyte);
            stream.write(value["data"].blob);
        }
    }

    if (INP_TAG_VENDOR in node) {
        writer.writeUTF8(INP_TAG_VENDOR);
        writer.writeBE!uint(cast(uint)node[INP_TAG_VENDOR].length);
        foreach(key, ref value; node[INP_TAG_VENDOR].object) {
            writer.writeBE!uint(cast(uint)key.length);
            writer.writeUTF8(key);
            writer.writeBE!uint(cast(uint)value.blob.length);
            stream.write(value.blob);
        }
    }
}




//
//              IMPLEMENTATION DETAILS
//
private:

ubyte[] makeJsonPayload(ref DataNode node) {
    scope MemoryStream stream = new MemoryStream(1);
    stream.writeJson(node);
    return stream.take();
}