
import 'tokens.dart';

class RuntimeError {
	String message;
	Token token;

	RuntimeError(Token token, String message) {
		this.token = token;
		this.message = message;
	}

}