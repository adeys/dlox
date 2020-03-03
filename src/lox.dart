import 'dart:io';

import 'env.dart';
import 'error_reporter.dart';
import 'interpreter.dart';
import 'module.dart';
import 'parser.dart';
import 'stmt.dart';

class Lox {
  static final String VERSION = '3.2';
	static Interpreter _interpreter;
  String _baseDir;
  File script = null;
  bool isRepl = false;
	
  Lox(List<String> _argv) {
    Environment env = new Environment(null);
    env.define('argv', _argv);

    _interpreter = new Interpreter(env);
    _interpreter.loadModule('std:core');
  }

	void prompt() {
    isRepl = true;
		stdout.writeln('Dart Lox v2.1');
		stdout.writeln('Hit Ctrl+C to quit\n');
    _baseDir = Directory.current.absolute.path;
    script = new File(Platform.script.toFilePath().split('/').last);

		while (true) {
			stdout.write('dlox> ');
			var res = run(stdin.readLineSync());
			res == null 
				? null 
				: stdout.writeln(stringify(res));
			ErrorReporter.hadError = false;
		}
	} 

	void runFile(String file) async {
		File program = new File(file);

    if (!program.existsSync()) {
      stderr.writeln("FileSystemError : File '$file' doesn't exist.");
      exit(75);
    }

    _baseDir = program.parent.absolute.path;
    script = program;
		run(program.readAsStringSync());

		if (ErrorReporter.hadError) exit(65);
		if (ErrorReporter.hadRuntimeError) exit(70);
	}

	Object run(String program) {
    ModuleResolver.baseDir = _baseDir;
    LoxModule module;
    
    if (isRepl) {
      module = new LoxModule("<repl>", new SourceFile("repl", program));
    } else {
      module = ModuleResolver.load(script.path);
    }

		Parser parser = new Parser.fromSource(module.source);
		List<Stmt> stmts = parser.parse();

		if (ErrorReporter.hadError) return null;

    module.statements = stmts;

		return _interpreter.interpret(module);
	}

}