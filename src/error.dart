
import 'tokens.dart';

class RuntimeError {
	String message;
	Token token;

	RuntimeError(Token token, String message) {
		this.token = token;
		this.message = message;
	}

}

class Return {
	final Object value;

	Return(Object val): value = val;
}

class Break {
  
}

class Throw {
  final Object value;

  Throw(Object val): value = val;
}