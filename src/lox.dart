import 'dart:io';

import 'expr.dart';
import 'lexer.dart';
import 'parser.dart';
import 'tokens.dart';
import '../tool/AstPrinter.dart';

class Lox {
	static bool errored = false;
	
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
		Expr expr = parser.parse();

		if (errored) return;

		print(new AstPrinter().print(expr));
	}

	static void error(int line, String message) {
		_report(line, "", message);
	}

	static void parseError(Token token, String message) {
		if (token.type == TokenType.EOF) {
			_report(token.line, " at end", message);
		} else {
			_report(token.line, " at '" + token.lexeme + "'", message);
		}
	}

	static void _report(int line, String where, String message) {
		stderr.writeln('[line $line]: Error $where: $message');
		errored = true;
	}
}