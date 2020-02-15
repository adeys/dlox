import '../env.dart';
import '../interpreter.dart';
import '../struct.dart';
import 'math.dart';

void registerStdLib(Environment env) {
  // Register globals
  env.define('clock', new NativeFunction((Interpreter interpreter, List<Object> args) {
    return DateTime.now().millisecondsSinceEpoch/1000;
  }, 0));

  env.define('typeof', new NativeFunction((Interpreter interpreter, List<Object> args) {
    Object arg = args[0];
    if (arg == null) {
      return 'nil';
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

  registerMath(env);
}