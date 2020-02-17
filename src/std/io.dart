import 'dart:io';

import '../env.dart';
import '../interpreter.dart';
import '../native.dart';

void registerIO(Environment env) {
  Map<String, NativeFunction> map = {
    // StdIO functions
    'in_read': new NativeFunction((Interpreter interpreter, List<Object> args) {
      return stdin.readLineSync();
    }, 0),
    'out_write': new NativeFunction((Interpreter interpreter, List<Object> args) {
      return stdout.write(args[0]);
    }, 1),
    'out_writeln': new NativeFunction((Interpreter interpreter, List<Object> args) {
      return stdout.writeln(args[0]);
    }, 1),
  };
  
  map.forEach((String name, NativeFunction func) {
    env.define('_io_$name', func);
  });
}