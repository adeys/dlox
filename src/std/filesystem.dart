import 'dart:io';

import '../env.dart';
import '../interpreter.dart';
import '../struct.dart';

void registerFilesystem(Environment env) {
  Map<String, NativeFunction> map = {
    'absolute': new NativeFunction((Interpreter interpreter, List<Object> args) {
      return args[0];// file.parent.absolute.path + '/' + args[0].toString().replaceFirst('/', '');
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
      file.renameSync(args[1]);
      return true;
    }, 2),
    'copy': new NativeFunction((Interpreter interpreter, List<Object> args) {
      File file = new File(args[0]);
      file.copySync(args[1]);
      return true;
    }, 2),
  };
  
  map.forEach((String name, NativeFunction func) {
    env.define('_fs_$name', func);
  });
}