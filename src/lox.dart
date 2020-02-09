import 'dart:io';

import 'error.dart';
import 'interpreter.dart';
import 'lexer.dart';
import 'parser.dart';
import 'resolver.dart';
import 'stmt.dart';
import 'tokens.dart';

class Lox {
	static bool hadError = false;
	static bool hadRuntimeError = false;

	static Interpreter _interpreter = new Interpreter();
	
	void prompt() {
		stdout.writeln('Dart Lox v1.1');
		stdout.writeln('Hit Ctrl+C to quit\n');

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
		run(program.readAsStringSync());

		if (hadError) exit(65);
		if (hadRuntimeError) exit(70);
	}

	Object run(String program) {
		Lexer lexer = new Lexer(program);

		List<Token> tokens = lexer.tokenize();
		Parser parser = new Parser(tokens);
		List<Stmt> stmts = parser.parse();

		if (hadError) return null;

		Resolver resolver = new Resolver(_interpreter);
		resolver.resolve(stmts);

		if (hadError) return null;

		return _interpreter.interpret(stmts);
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
		hadError = true;
	}
}