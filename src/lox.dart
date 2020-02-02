import 'dart:io';

import 'error.dart';
import 'expr.dart';
import 'interpreter.dart';
import 'lexer.dart';
import 'parser.dart';
import 'stmt.dart';
import 'tokens.dart';

class Lox {
	static bool errored = false;
	static bool hadRuntimeError = false;

	static Interpreter _interpreter = new Interpreter();
	
	void prompt() {
		stdout.writeln('Dart Lox v1.0');
		stdout.writeln('Hit Ctrl+C to quit\n');

		while (true) {
			stdout.write('dlox> ');
			run(stdin.readLineSync());
			errored = false;
		}
	} 

	void runFile(String file) async {
		File program = new File(file);
		run(program.readAsStringSync());

		if (errored) exit(65);
	}

	void run(String program) {
		Lexer lexer = new Lexer(program);

		List<Token> tokens = lexer.tokenize();
		Parser parser = new Parser(tokens);
		List<Stmt> stmts = parser.parse();

		if (errored) exit(65);
		if (hadRuntimeError) exit(70);

		_interpreter.interpret(stmts);
	}

	static void error(int line, String message) {
		_report(line, "", message);
	}

	static void parseError(Token token, String message) {
		if (token.type == TokenType.EOF) {
			_report(token.line, "at end", message);
		} else {
			_report(token.line, "at '" + token.lexeme + "'", message);
		}
	}

	static void runtimeError(RuntimeError err) {
		stderr.writeln(err.message + '\n[line ' + err.token.line.toString() + '].');
		hadRuntimeError = true;
	}

	static void _report(int line, String where, String message) {
		stderr.writeln('[line $line]: Error $where: $message');
		errored = true;
	}
}