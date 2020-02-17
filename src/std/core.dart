import '../env.dart';
import '../error.dart';
import '../interpreter.dart';
import '../native.dart';
import '../struct.dart';
import '../tokens.dart';
import 'filesystem.dart';
import 'io.dart';
import 'math.dart';
import 'string.dart';

void registerStdLib(Interpreter interpreter) {
  Environment env = interpreter.globals;
  // Register globals
  env.define('clock', new NativeFunction((Interpreter interpreter, List<Object> args) {
    return DateTime.now().millisecondsSinceEpoch/1000;
  }, 0));

  env.define('typeof', new NativeFunction((Interpreter interpreter, List<Object> args) {
    Object arg = args[0];
    if (arg == null) {
      return 'nil';
    } else if (arg is bool) {
      return 'boolean';
    } else if (arg is num) {
      return 'number';
    } else if (arg is String) {
      return 'string';
    } else if (arg is LoxFunction || arg is NativeFunction) {
      return 'function';
    } else if (arg is LoxInstance) {
      return 'object';
    } else {
      return 'class';
    }
  }, 1));

  env.define('exit', new NativeFunction((Interpreter interpreter, List<Object> args) {
    throw new Exit((args[0] as double).toInt());
  }, 1));

  env.define('Array', new NativeFunction((Interpreter interpreter, List<Object> args) {
    LoxArray array = new LoxArray();
    array.stringify = interpreter.stringify;

    return array;
  }, 0));

  interpreter.registerNative("Math", new LoxMathClass());
  interpreter.registerNative("String", new LoxStringClass());
  interpreter.registerNative("Path", new LoxPathClass());
  interpreter.registerNative("Stat", new LoxStatClass());
  interpreter.registerNative("File", new LoxFileClass());
  interpreter.registerNative("Directory", new LoxDirectoryClass());
  interpreter.registerNative("Stdin", new LoxStdinClass());
  interpreter.registerNative("Stdout", new LoxStdoutClass());
  interpreter.registerNative("List", new LoxListClass());
  interpreter.registerNative("Map", new LoxMapClass());
}

// Hacked trick to declare 'List' and 'Map' as native classes
// to prevent users from settings props dynamically
class LoxListClass extends NativeClass {
  LoxListClass() : super("List") {
    allowedFields = ["_store"];
  }

}
class LoxMapClass extends NativeClass {
  LoxMapClass() : super("Map") {
    allowedFields = ["_size", "_keys", "_items"];
  }

}

// Declare builtin 'Array' class
class LoxArray extends LoxInstance {
  List<Object> _elements = [];
  Map<String, NativeFunction> methods;
  Function stringify;

  LoxArray() : super(null) {
    methods = {
      'get': new NativeFunction((Interpreter interpreter, List<Object> args) {
        int index = (args[0] as num)?.toInt();
        if (index != null) {
          if (index >= _elements.length) return interpreter.stringify(null);

          return _elements[index];
        }

        return null;
      }, 1),
      'set': new NativeFunction((Interpreter interpreter, List<Object> args) {
        int index = (args[0] as num)?.toInt();
        if (index != null) {
          if (index >= _elements.length) return;

          _elements[index] = args[1];
        }
      }, 2),
      'add': new NativeFunction((Interpreter interpreter, List<Object> args) {
        _elements.add(args[0]);
      }, 1),
      'remove': new NativeFunction((Interpreter interpreter, List<Object> args) {
        int index = (args[0] as num)?.toInt();
        if (index != null) {
          _elements.removeAt(index);
        }
      }, 1),
    };
  }

  @override
  void set(Token field, Object value) {
    throw new RuntimeError(field, "Cannot add properties to native class 'Array'.");
  }

  @override
  Object get(Token field, Interpreter interpreter) {
    if (field.lexeme == 'length') return _elements.length;

    if (methods.containsKey(field.lexeme)) {
      return methods[field.lexeme];
    }

		throw new RuntimeError(field, "Undefined property '${field.lexeme}' in class 'Array'.");
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();

    buffer.write("[");
    for (int i = 0; i < _elements.length; i++) {
      if (i != 0) buffer.write(", ");
      buffer.write(stringify(_elements[i]));
    }
    buffer.write("]");
    
    return buffer.toString();
  }
}