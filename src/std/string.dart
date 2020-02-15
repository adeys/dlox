import '../env.dart';
import '../interpreter.dart';
import '../struct.dart';


void registerString(Environment env) {
  Map<String, NativeFunction> map = {
    'length': new NativeFunction((Interpreter _, List<Object> args) {
      return args[0].toString().length;
    }, 1),
    'to_lower': new NativeFunction((Interpreter _, List<Object> args) {
      return (args[0] as String).toLowerCase();
    }, 1),
    'to_upper': new NativeFunction((Interpreter _, List<Object> args) {
      return (args[0] as String).toUpperCase();
    }, 1),
    'to_lower': new NativeFunction((Interpreter _, List<Object> args) {
      return (args[0] as String).toLowerCase();
    }, 1),
    'trim': new NativeFunction((Interpreter _, List<Object> args) {
      return (args[0] as String).trim();
    }, 1),
    'substr': new NativeFunction((Interpreter _, List<Object> args) {
      try {
        return (args[0] as String).substring(
          (args[1] as double).toInt(), 
          args[2] is double ? (args[2] as double).toInt() : null
        );
      } on RangeError {
        return "";
      }
    }, 3)
  };
  
  map.forEach((String name, NativeFunction func) {
    env.define('_str_$name', func);
  });
}