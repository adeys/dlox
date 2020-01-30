import 'dart:io';

import 'lexer.dart';
import 'tokens.dart';

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

		for (Token token in tokens) {
			print(token);
		}
	}

	static void error(int line, String message) {
		report(line, "", message);
	}

	static void report(int line, String where, String message) {
		stderr.writeln('[line $line]: Error $where: $message');
		errored = true;
	}
}