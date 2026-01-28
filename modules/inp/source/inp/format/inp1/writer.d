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

@nogc:

/**
    Write the contents of a $(D DataNode) into the INP1 File.

    Params:
        stream =    The stream to write to.
        node =      A DataNode object following the INP structure.
*/
void writeINP1(Stream stream, ref DataNode node) {
    scope  StreamWriter writer = new StreamWriter(stream);

    if (INP1_MAGIC in node) {
        writer.writeUTF8(INP1_MAGIC);

        ubyte[] payload = node[INP1_MAGIC].makeJsonPayload();
        writer.writeBE!uint(cast(uint)payload.length);
        stream.write(payload);

        nu_freea(payload);
    }

    if ("TEX_SECT" in node) {
        writer.writeUTF8("TEX_SECT");
        writer.writeBE!uint(cast(uint)node["TEX_SECT"].length);
        foreach(ref value; node["TEX_SECT"].array) {
            writer.writeBE!uint(cast(uint)value["data"].blob.length);
            writer.writeBE!ubyte(value["encoding"].tryCoerce!ubyte);
            stream.write(value["data"].blob);
        }
    }

    if ("EXT_SECT" in node) {
        writer.writeUTF8("EXT_SECT");
        writer.writeBE!uint(cast(uint)node["EXT_SECT"].length);
        foreach(key, ref value; node["EXT_SECT"].object) {
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