import 'dart:io';

import 'error.dart';
import 'interpreter.dart';
import 'module.dart';
import 'parser.dart';
import 'stmt.dart';
import 'tokens.dart';

class Lox {
	static bool hadError = false;
	static bool hadRuntimeError = false;

	static Interpreter _interpreter;
  String _baseDir;
  File script = null;
	
  Lox() {
    _interpreter = new Interpreter(this);
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
			hadError = false;
		}
	} 

	void runFile(String file) async {
		File program = new File(file);
    _baseDir = program.parent.absolute.path;
    script = program;
		run(program.readAsStringSync());

		if (hadError) exit(65);
		if (hadRuntimeError) exit(70);
	}

	Object run(String program) {
    ModuleResolver.baseDir = _baseDir;
    LoxModule module = ModuleResolver.load(script.path);

		Parser parser = new Parser.fromSource(module.source);
		List<Stmt> stmts = parser.parse();

		if (hadError) return null;

    module.statements = stmts;

		return _interpreter.interpret(module);
	}

	static void error(String file, int line, String message) {
		_report(file, line, "", message);
	}

	static void parseError(Token token, String message) {
		if (token.type == TokenType.EOF) {
			_report(token.file, token.line, "at end", message);
		} else {
			_report(token.file, token.line, "at '" + token.lexeme + "'", message);
		}
	}

	static void runtimeError(RuntimeError err) {
		stderr.writeln(err.message + '\n[line ' + err.token.line.toString() + '](file: ${err.token.file}).');
		hadRuntimeError = true;
	}

	static void _report(String file, int line, String where, String message) {
		stderr.writeln('[line $line]: Error $where: $message(file: ${file})');
		hadError = true;
	}
}