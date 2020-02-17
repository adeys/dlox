import 'dart:io';

import '../interpreter.dart';
import '../native.dart';

class LoxStdinClass extends NativeClass {
  LoxStdinClass() : super("Stdin") {
    staticMethods = {
      'readline': new NativeFunction((Interpreter interpreter, List<Object> args) {
        return stdin.readLineSync();
      }, 0),
    };
  }

}

class LoxStdoutClass extends NativeClass {
  LoxStdoutClass() : super("Stdout") {
    staticMethods = {
      'readline': new NativeFunction((Interpreter interpreter, List<Object> args) {
        return stdin.readLineSync();
      }, 0),
      'write': new NativeFunction((Interpreter interpreter, List<Object> args) {
        return stdout.write(args[0]);
      }, 1),
      'writeln': new NativeFunction((Interpreter interpreter, List<Object> args) {
        return stdout.writeln(args[0]);
      }, 1),
    };
  }

}