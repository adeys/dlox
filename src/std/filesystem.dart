import 'dart:io';

import '../env.dart';
import '../interpreter.dart';
import '../struct.dart';

void registerFilesystem(Environment env) {
  Map<String, NativeFunction> map = {
    // File management functions
    'absolute': new NativeFunction((Interpreter interpreter, List<Object> args) {
      return File(interpreter.currentModule.source.file)
        .parent.path
        .replaceAll(new RegExp('/\\.\$'), '/') + args[0].toString().replaceAll(new RegExp('^\\./'), '');
    }, 1),
    'stat_exists': new NativeFunction((Interpreter interpreter, List<Object> args) {
      File file = new File(args[0]);
      return file.existsSync();
    }, 1),
    'write_file': new NativeFunction((Interpreter interpreter, List<Object> args) {
      File file = new File(args[0]);
      file.writeAsStringSync(args[1], mode: args[2] ? FileMode.write : FileMode.append, flush: true);
      return true;
    }, 3),
    'read_file': new NativeFunction((Interpreter interpreter, List<Object> args) {
      File file = new File(args[0]);
      return file.readAsStringSync();
    }, 1),
    'rename_file': new NativeFunction((Interpreter interpreter, List<Object> args) {
      File file = new File(args[0]);
      return file.renameSync(args[1]).absolute.path;
    }, 2),
    'copy_file': new NativeFunction((Interpreter interpreter, List<Object> args) {
      File file = new File(args[0]);
      file.copySync(args[1]);
      return true;
    }, 2),
    'create_file': new NativeFunction((Interpreter interpreter, List<Object> args) {
      try {
        File file = new File(args[0]);
        file.createSync(recursive: true);
        return true;
      } catch (_) {
        return false;
      }
    }, 1),
    'delete_file': new NativeFunction((Interpreter interpreter, List<Object> args) {
      try {
        File file = new File(args[0]);
        file.deleteSync(recursive: true);
        return true;
      } catch (_) {
        return false;
      }
    }, 1),

    // Directory management functions
  };
  
  map.forEach((String name, NativeFunction func) {
    env.define('_fs_$name', func);
  });
}