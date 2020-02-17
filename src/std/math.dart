import 'dart:math';

import '../interpreter.dart';
import '../native.dart';

class LoxMathClass extends NativeClass {
  LoxMathClass() : super("Math") {
    staticMethods = {
      'pow': new NativeFunction((Interpreter _, List<Object> args) {
        return pow(args[0], args[1]);
      }, 2),
      'sin': new NativeFunction((Interpreter _, List<Object> args) {
        return sin(args[0]);
      }, 1),
      'cos': new NativeFunction((Interpreter _, List<Object> args) {
        return cos(args[0]);
      }, 1),
      'tan': new NativeFunction((Interpreter _, List<Object> args) {
        return tan(args[0]);
      }, 1),
      'sqrt': new NativeFunction((Interpreter _, List<Object> args) {
        return sqrt(args[0]);
      }, 1),
      'exp': new NativeFunction((Interpreter _, List<Object> args) {
        return exp(args[0]);
      }, 1),
      'log': new NativeFunction((Interpreter _, List<Object> args) {
        return log(args[0]);
      }, 1),
      'pi': new NativeFunction((Interpreter _, List<Object> args) {
        return pi;
      }, -1),
    };
  }
}