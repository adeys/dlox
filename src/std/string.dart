import '../interpreter.dart';
import '../native.dart';
import '../struct.dart';
import '../tokens.dart';

class LoxStringClass extends NativeClass {
  LoxStringClass() : super("String") {
    Token name = new Token(TokenType.STRING, "str", null, null, null);
    allowedFields = ['str'];

    methods = {
      'construct': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        instance.set(name, args[0].toString());
      }, 1), 
      'length': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        return instance.get(name, interpreter).toString().length;
      }, -1),
      'toLower': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        instance.set(name, instance.get(name, interpreter).toString().toLowerCase());
        return instance;
      }, 0),
      'toUpper': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        instance.set(name, instance.get(name, interpreter).toString().toUpperCase());
        return instance;
      }, 0),
      'trim': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        instance.set(name, instance.get(name, interpreter).toString().trim());
        return instance;
      }, 0),
      'substr': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        try {
          int start = (args[0] as double).toInt();
          int end = args[1] is double ? ((args[1] as double).toInt() + start) : null;
          return instance.get(name, interpreter).toString().substring(start, end); 
        } on RangeError {
          return "";
        }
      }, 2),
      'startsWith': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        return instance.get(name, interpreter).toString().startsWith(args[0].toString());
      }, 1),
      'charCodeAt': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");
        int index = (args[0] as num)?.toInt();

        String str = instance.get(name, interpreter).toString();
        if (index == null || index >= str.length) return -1;

        return str.codeUnitAt(index);
      }, 1),
      'toString': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        return instance.get(name, interpreter).toString();
      }, 0),
    };
  }

}