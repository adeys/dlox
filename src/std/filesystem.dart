import 'dart:io';

import '../interpreter.dart';
import '../native.dart';
import '../struct.dart';
import '../tokens.dart';

class LoxPathClass extends NativeClass {
  LoxPathClass() : super("Path") {
    staticMethods = {
      "resolve": new NativeFunction((Interpreter interpreter, List<Object> args) {
        bool isDir = args[1] == true;
        String base = Directory(interpreter.currentModule.source.file).parent.path;
        String relative = isDir ? args[0] : args[0].toString();

        return Directory(base + '/' + relative).resolveSymbolicLinksSync();
      }, 2),
    };
  }
}

class LoxStatClass extends NativeClass {
  LoxStatClass() : super("Stat") {
    NativeFunction exists = new NativeFunction((Interpreter interpreter, List<Object> args) {
        bool isDir = args[1] == true;
        var file = isDir ? new Directory(args[0]) : new File(args[0]);
        return file.existsSync();
      }, 2);

    staticMethods = {
      'exists': exists,
      'isDir': new NativeFunction((Interpreter interpreter, List<Object> args) {
        return Directory(args[0]).existsSync();
      }, 1),
      'isFile': new NativeFunction((Interpreter interpreter, List<Object> args) {
        return File(args[0]).existsSync();
      }, 1),
      'size': new NativeFunction((Interpreter interpreter, List<Object> args) {
        return exists.callFn(interpreter, [args[0], false])
          ? (FileStat.statSync(args[0]).size / 1024).toStringAsPrecision(2)
          : 0;
      }, 1),
    };
  }

}

class LoxFileClass extends NativeClass {
  LoxFileClass() : super("File") {
    Token path = new Token(TokenType.STRING, "_path", null, null, null);
    allowedFields = ['_path'];

    methods = {
      '_write': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        File file = new File(instance.get(path, interpreter));
        file.writeAsStringSync(args[0], mode: args[1] ? FileMode.write : FileMode.append, flush: true);
        return true;
      }, 2),
      '_read': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        File file = new File(instance.get(path, interpreter));
        return file.readAsStringSync();
      }, 0),
      '_rename': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        File file = new File(instance.get(path, interpreter));
        return file.renameSync(args[0]).absolute.path;
      }, 1),
      '_copy': new NativeMethod((Interpreter interpreter, List<Object> args) {
        LoxInstance instance = interpreter.env.getAt(0, "this");

        File file = new File(instance.get(path, interpreter));
        file.copySync(args[0]);
        return true;
      }, 1),
      '_create': new NativeMethod((Interpreter interpreter, List<Object> args) {
        try {
          LoxInstance instance = interpreter.env.getAt(0, "this");

          File file = new File(instance.get(path, interpreter));

          file.createSync(recursive: true);
          return true;
        } catch (_) {
          return false;
        }
      }, 0),
      '_delete': new NativeMethod((Interpreter interpreter, List<Object> args) {
        try {
          LoxInstance instance = interpreter.env.getAt(0, "this");

          File file = new File(instance.get(path, interpreter));

          file.deleteSync(recursive: true);
          return true;
        } catch (_) {
          return false;
        }
      }, 0),
    };
  }
}

class LoxDirectoryClass extends NativeClass {
  LoxDirectoryClass() : super("Directory") {
    allowedFields = ['_path', '_files'];

    methods = {
      '_list': new NativeMethod((Interpreter interpreter, List<Object> args) {
        // Assume list class was declared, use it to send back result;
        Token method = new Token(TokenType.IDENTIFIER, "push", null, null, -1);
        
        LoxInstance list = (interpreter.globals.getAt(0, "List") as LoxClass).callFn(interpreter, []);
        LoxFunction push = list.get(method, interpreter);

        LoxInstance instance = interpreter.env.getAt(0, "this");

        Directory dir = new Directory(instance.get(
          new Token(TokenType.IDENTIFIER, "_path", null, null, null), 
          interpreter));

        dir.listSync().forEach((FileSystemEntity entity) {
          push.callFn(interpreter, [entity.path]);
        });

        return list;
      }, 0),
    };
  }

}