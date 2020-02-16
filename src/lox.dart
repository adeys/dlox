import 'dart:io';

import 'error_reporter.dart';
import 'interpreter.dart';
import 'module.dart';
import 'parser.dart';
import 'stmt.dart';

class Lox {

	static Interpreter _interpreter;
  String _baseDir;
  File script = null;
	
  Lox() {
    _interpreter = new Interpreter();
  }

	void prompt() {
		stdout.writeln('Dart Lox v2.1');
		stdout.writeln('Hit Ctrl+C to quit\n');
    _baseDir = Directory.current.absolute.path;

		while (true) {
			stdout.write('dlox> ');
			var res = run(stdin.readLineSync());
			res == null 
				? null 
				: stdout.writeln(_interpreter.stringify(res));
			ErrorReporter.hadError = false;
		}
	} 

	void runFile(String file) async {
		File program = new File(file);
    _baseDir = program.parent.absolute.path;
    script = program;
		run(program.readAsStringSync());

		if (ErrorReporter.hadError) exit(65);
		if (ErrorReporter.hadRuntimeError) exit(70);
	}

	Object run(String program) {
    ModuleResolver.baseDir = _baseDir;
    LoxModule module = ModuleResolver.load(script.path);

		Parser parser = new Parser.fromSource(module.source);
		List<Stmt> stmts = parser.parse();

		if (ErrorReporter.hadError) return null;

    module.statements = stmts;

		return _interpreter.interpret(module);
	}

}