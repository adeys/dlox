import 'dart:io';

import 'env.dart';
import 'stmt.dart';

class SourceFile {
  final String file;
  final String source;

  SourceFile(this.file, this.source);
}

class LoxModule {
  final String name;
  final SourceFile source;
  List<Stmt> statements = [];
  Environment scope = new Environment(null);

  LoxModule(String _name, SourceFile _source): 
    source = _source, name = _name;

}

class ModuleResolver {
  static String baseDir = "";
  static String _coreLibDir = File.fromUri(Platform.script).parent.absolute.path + '/lib';

  static LoxModule load(String name) {
    String path = resolve(name);
    File file = new File(path);

    SourceFile source = new SourceFile(file.absolute.path, file.readAsStringSync());

    return new LoxModule(name, source);
  }

  static String resolve(String name) {
    bool isCore = false;
    String path;

    if (!name.startsWith('lox:')) {
      path = baseDir +  '/' + name.replaceFirst('/', '');
    } else {
      isCore = true;
      path = name.split(':')[1];
      path = "$_coreLibDir/$path.lox";
    }
    
    File file = new File(path);
    if (!file.existsSync()) {
      throw "${isCore ? 'Library' : 'File'} '${name}' not found.";
    }
    
    return path;
  }
}