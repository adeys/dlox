import '../env.dart';
import '../error.dart';
import '../interpreter.dart';
import '../native.dart';
import '../struct.dart';
import 'filesystem.dart';
import 'io.dart';
import 'math.dart';
import 'string.dart';

void registerStdLib(Environment env) {
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

  env.define("Math", new LoxMathClass());
  env.define("String", new LoxStringClass());
  registerFilesystem(env);
  registerIO(env);
}