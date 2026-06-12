/**
    JSON Reader

    Copyright © 2020-2025, Inochi2D Project
    Distributed under the 2-Clause BSD License, see LICENSE file.
    
    Authors: Luna Nielsen
*/
module inp.format.json.reader;
import inp.format.node;
import nulib.io.stream;
import nulib.io.stream.rw;
import nulib.string;
import nulib.math;
import numem;

@nogc:

/**
    Reads and parses a JSON string into a $(D DataNode).

    Params:
        stream = The stream to read.
    
    Returns:
        A result type containing either a $(D DataNode)
        or an error message.
*/
Result!DataNode readJson(Stream stream) @nogc {
    scope StreamReader reader = new StreamReader(stream);
    DataNode result;

    if (auto err = reader.readJsonImpl(result, reader.stream.tell, reader.stream.length))
        return error!DataNode(err);
    return ok(result.move());
}

/**
    Reads and parses a JSON string into the given $(D DataNode).

    Params:
        reader =    The stream reader.
        node =      The node to write to.
        length =    Max length to read.
    
    Returns:
        $(D null) on success,
        otherwise an error message.

*/
string readJson(StreamReader reader, ref DataNode node, uint length = uint.max) @nogc {
    return reader.readJsonImpl(node, reader.stream.tell, min(length, reader.stream.length-reader.stream.tell));
}




//
//              IMPLEMENTATION DETAILS
//
private:

char peekChar(StreamReader reader) {
    char c = cast(char)reader.readU8();
    reader.stream.seek(-1, SeekOrigin.relative);
    return c;
}

string peek(StreamReader reader, uint length) {
    auto s = reader.read(length);
    if (s.length > 0) {
        reader.stream.seek(-cast(ptrdiff_t)s.length, SeekOrigin.relative);
    }
    return s;
}

bool peek(StreamReader reader, string key) {
    string read = reader.peek(cast(uint)key.length);
    bool same = key == read;
    nu_freea(read);
    return same;
}

string read(StreamReader reader, uint length) {
    return reader.readUTF8(length).take();
}

string popString(StreamReader reader, string key) {
    auto read = reader.readUTF8(cast(uint)key.length);
    if (read == key) {
        return key;
    }

    reader.stream.seek(-cast(ptrdiff_t)read.length, SeekOrigin.relative);
    return null;
}

string readJsonString(StreamReader reader) {

    // Skip initial quote.
    if (reader.peekChar() == '"') {
        reader.stream.seek(1, SeekOrigin.relative);
    }

    nstring result;
    char c;
    do {
        c = cast(char)reader.readU8();
        if (c == '"')
            break;
        
        result ~= c;

        // Read escape codes.
        if (c == '\\') {
            c = cast(char)reader.readU8();
            result ~= c;
        }
    } while(c != '"');
    return result.take();
}

string readJsonNumber(StreamReader reader) {
    nstring result;
    char c;

    do {
        c = cast(char)reader.readU8();
        result ~= c;
    } while (isNumberChar(c));

    reader.stream.seek(-1, SeekOrigin.relative);
    return result.take();
}

bool isJsonSymbol(char c) {
    import nulib.text.ascii;
    return isAlphaNumeric(c) || 
        c == '"' || c == ':' || c == ',' || 
        c == '{' || c == '}' ||
        c == '[' || c == ']' || c == '.';
}

void skipWhitespace(StreamReader reader) {
    do { } while(!isJsonSymbol(cast(char)reader.readU8()));
    reader.stream.seek(-1, SeekOrigin.relative);
}

bool isNumberChar(char c) {
    return (c >= '0' && c <= '9') || c == '.' || c == '-' || c == '+';
}

string readJsonImpl()(StreamReader reader, ref DataNode node, size_t start, size_t length) {
    import nulib.conv : parseFloat;

    reader.skipWhitespace();
    if (reader.stream.tell() >= start+length)
        return "Reached EOF";


    char c = cast(char)reader.readU8();
    switch(c) {
        default:
            reader.stream.seek(-1, SeekOrigin.relative);
            if (isNumberChar(c)) {
                
                auto valueStr = reader.readJsonNumber();
                node = DataNode(parseFloat!double(valueStr));
                nu_freea(valueStr);
                return null;
            }

            if (reader.peek("true")) {
                reader.stream.seek(4, SeekOrigin.relative);
                node = DataNode(true);
                return null;
            }

            if (reader.peek("false")) {
                reader.stream.seek(5, SeekOrigin.relative);
                node = DataNode(false);
                return null;
            }

            // Skip 'null'
            if (reader.peek("null")) {
                reader.stream.seek(4, SeekOrigin.relative);
                return null;
            }

            // Okay, no idea what this character is.
            return "Unexpected token";

        case '[':
            node = DataNode.createArray();
            
            // Empty array.
            if (reader.peekChar() == ']') {
                reader.stream.seek(1, SeekOrigin.relative);
                return null;
            }

            do {
                DataNode value;

                reader.skipWhitespace();
                if (auto error = reader.readJsonImpl(value, start, length))
                    return error;
                node ~= value.move();
                reader.skipWhitespace();

                c = cast(char)reader.readU8();
                if (c == ',')
                    continue;
                
            } while(c != ']');
            return null;

        case '{':
            node = DataNode.createObject();
            
            // Empty object.
            if (reader.peekChar() == '}') {
                reader.stream.seek(1, SeekOrigin.relative);
                return null;
            }

            do {
                DataNode value;

                // Get key
                reader.skipWhitespace();
                string key = reader.readJsonString();
                reader.skipWhitespace();

                c = cast(char)reader.readU8();
                if (c != ':')
                    return "Invalid key-value pair!";
                    
                reader.skipWhitespace();
                if (auto error = reader.readJsonImpl(value, start, length)) {
                    nu_freea(key);
                    return error;
                }
                reader.skipWhitespace();

                node[key] = value.move();
                nu_freea(key);

                c = cast(char)reader.readU8();
                if (c == ',')
                    continue;
                
            } while(c != '}');
            return null;

        case '"':
            string value = reader.readJsonString();
            node = DataNode(value);
            nu_freea(value);
            return null;
    }
}