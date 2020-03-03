import 'dart:collection';
import 'dart:io';

import '../env.dart';
import '../error.dart';
import '../interpreter.dart';
import '../lox.dart';
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

  env.define('str', new NativeFunction((Interpreter interpreter, List<Object> args) {
    return stringify(args[0]);
  }, 1));

  env.define('num', new NativeFunction((Interpreter interpreter, List<Object> args) {
    return double.tryParse(args[0].toString());
  }, 1));

  env.define('print', new NativeFunction((Interpreter interpreter, List<Object> args) {
    return stdout.write(stringify(args[0]));
  }, 1));

  env.define('println', new NativeFunction((Interpreter interpreter, List<Object> args) {
    return stdout.writeln(stringify(args[0]));
  }, 1));

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
    exit((args[0] as num)?.toInt() ?? 0);
  }, 1));

  env.define('error', new NativeFunction((Interpreter interpreter, List<Object> args) {
    stderr.writeln(args[0].toString());
  }, 1));

  env.define('Array', new NativeFunction((Interpreter interpreter, List<Object> args) {
    LoxArray array = new LoxArray();

    return array;
  }, 0));

  env.define('Process', new LoxProcess(env.get(new Token(TokenType.IDENTIFIER, 'argv', null, '', -1))));

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

class LoxProcess extends LoxInstance {
	final Map<String, Object> _fields = new HashMap();
  Map<String, NativeFunction> methods;
  
  LoxProcess(List<String> argv) : super(null) {
    _fields['os'] = Platform.operatingSystem;
    _fields['script'] = Platform.script.toFilePath();
    _fields['argv'] = new LoxArray(argv.length != 0 ? argv.sublist(1) : []);
    _fields['argc'] = argv.length - 1;
    _fields['version'] = Lox.VERSION;

    methods = {
      'filename': new NativeFunction((Interpreter interpreter, List<Object> args) {
        return interpreter.currentModule.source.file;
      }, 0),
      'dirname': new NativeFunction((Interpreter interpreter, List<Object> args) {
        return new File(interpreter.currentModule.source.file).parent.absolute.path;
      }, 0),
    };
  }

  @override
  void set(Token field, Object value) {
    throw new RuntimeError(field, "Cannot add properties to native class 'Process'.");
  }

  @override
  Object get(Token field, Interpreter interpreter) {
    if (_fields.containsKey(field.lexeme)) return _fields[field.lexeme];

    if (methods.containsKey(field.lexeme)) {
      return methods[field.lexeme];
    }

		throw new RuntimeError(field, "Undefined property '${field.lexeme}' in class 'Process'.");
  }

  @override
  String toString() {
    return '<native_object Process>';
  }

}

// Declare builtin 'Array' class
class LoxArray extends LoxInstance {
  List<Object> _elements;
  Map<String, NativeFunction> methods;
  Function _stringify = stringify;

  LoxArray([List<Object> elements]) : super(null) {
    _elements = elements == null ? [] : elements;
    methods = {
      'get': new NativeFunction((Interpreter interpreter, List<Object> args) {
        int index = args[0] is num ? (args[0] as num)?.toInt() : null;
        if (index != null) {
          if (index >= _elements.length) return _stringify(null);

          return _elements[index];
        }

        return null;
      }, 1),
      'set': new NativeFunction((Interpreter interpreter, List<Object> args) {
        int index = args[0] is num ? (args[0] as num)?.toInt() : null;
        if (index != null) {
          if (index >= _elements.length) return;

          _elements[index] = args[1];
        }
      }, 2),
      'add': new NativeFunction((Interpreter interpreter, List<Object> args) {
        _elements.add(args[0]);
      }, 1),
      'remove': new NativeFunction((Interpreter interpreter, List<Object> args) {
        int index = args[0] is num ? (args[0] as num)?.toInt() : null;
        if (index != null) {
          return _elements.removeAt(index);
        }

        return null;
      }, 1),
      'indexOf': new NativeFunction((Interpreter interpreter, List<Object> args) {
        return _elements.indexOf(args[0]);
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
      buffer.write(_stringify(_elements[i]));
    }
    buffer.write("]");
    
    return buffer.toString();
  }
}