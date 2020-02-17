import 'dart:io';

import '../env.dart';
import '../interpreter.dart';
import '../native.dart';
import '../struct.dart';
import '../tokens.dart';

void registerFilesystem(Environment env) {
  Map<String, NativeFunction> map = {
    // File management functions
    'absolute': new NativeFunction((Interpreter interpreter, List<Object> args) {
      bool isDir = args[1] == true;
      String base = Directory(interpreter.currentModule.source.file).parent.path;
			String relative = isDir ? args[0] : args[0].toString();

			return Directory(base + '/' + relative).resolveSymbolicLinksSync();
    }, 2),
    'stat_exists': new NativeFunction((Interpreter interpreter, List<Object> args) {
      bool isDir = args[1] == true;
			var file = isDir ? new Directory(args[0]) : new File(args[0]);
      return file.existsSync();
    }, 2),
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
    'list_dir': new NativeFunction((Interpreter interpreter, List<Object> args) {
			// Assume list class was declared, use it to send back result;
      Token method = new Token(TokenType.IDENTIFIER, "push", null, null, -1);
			
      LoxInstance inst = (env.getAt(0, "List") as LoxClass).callFn(interpreter, []);
      LoxFunction push = inst.get(method, interpreter);

      Directory dir = new Directory(args[0]);print(args[0]);
      dir.listSync().forEach((FileSystemEntity entity) {
        push.callFn(interpreter, [entity.path]);
      });

      return inst;
    }, 1),

		// Stats related functions
		'stat_isdir': new NativeFunction((Interpreter interpreter, List<Object> args) {
			return Directory(args[0]).existsSync();
    }, 1),
		'stat_isfile': new NativeFunction((Interpreter interpreter, List<Object> args) {
			return File(args[0]).existsSync();
    }, 1),
		'stat_size': new NativeFunction((Interpreter interpreter, List<Object> args) {
			return (FileStat.statSync(args[0]).size / 1024).toStringAsPrecision(2);
    }, 1),
  };
  
  map.forEach((String name, NativeFunction func) {
    env.define('_fs_$name', func);
  });
}