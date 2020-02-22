import 'dart:io';

import 'error.dart';
import 'tokens.dart';

class ErrorReporter {
  static bool hadError = false;
  static bool hadRuntimeError = false;


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
		stderr.writeln('[line ' + err.token.line.toString() + '] Runtime Error : ' + err.message + '\n(file: ${err.token.file}).');
		hadRuntimeError = true;
	}

	static void _report(String file, int line, String where, String message) {
		stderr.writeln('[line $line]: Error $where: $message(file: ${file})');
		hadError = true;
	}
}