import '../interpreter.dart';
import '../native.dart';
import '../struct.dart';
import '../tokens.dart';

class LoxStringClass extends NativeClass {
  LoxStringClass() : super("String") {
    Token name = new Token(TokenType.STRING, "str", null, null, null);

    methods = {
      'construct': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        instance.set(name, args[0].toString());
      }, null, 1), 
      'length': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        return instance.get(name, interpreter).toString().length;
      }, null, -1),
      'toLower': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        return instance.get(name, interpreter).toString().toLowerCase();
      }, null, 0),
      'toUpper': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        return instance.get(name, interpreter).toString().toUpperCase();
      }, null, 0),
      'trim': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        return instance.get(name, interpreter).toString().trim();
      }, null, 0),
      'substr': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        try {
          int start = (args[0] as double).toInt();
          int end = args[1] is double ? ((args[1] as double).toInt() + start) : null;
          return instance.get(name, interpreter).toString().substring(start, end); 
        } on RangeError {
          return "";
        }
      }, null, 2),
      'startsWith': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        return instance.get(name, interpreter).toString().startsWith(args[0].toString());
      }, null, 1),
      'toString': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        return instance.get(name, interpreter).toString();
      }, null, 1),
    };
  }

}