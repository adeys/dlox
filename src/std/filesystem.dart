import '../env.dart';
import '../struct.dart';

void registerFilesystem(Environment env) {
  Map<String, NativeFunction> map = {
    
  };
  
  map.forEach((String name, NativeFunction func) {
    env.define('_fs_$name', func);
  });
}