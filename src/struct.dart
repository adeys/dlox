import 'env.dart';
import 'error.dart';
import 'interpreter.dart';
import 'stmt.dart';

abstract class LoxCallable {

	Object call(Interpreter interpreter, List<Object> args);

	int arity();
}

class NativeFunction implements LoxCallable {
	Function callable;
	int _arity = -1;

	NativeFunction(Function callable, int arity) {
		this.callable = callable;
		_arity = arity;
	}

	Object call(Interpreter interpreter, List<Object> args) {;
		return callable(interpreter, args);
	}

	int arity() {return _arity;}

	@override
	String toString() {
		return '<native fn>';
	}
}

class LoxFunction implements LoxCallable {
	final FunctionStmt _stmt;
	final Environment _closure;

	LoxFunction(FunctionStmt stmt, Environment env): _stmt = stmt, _closure = env {
		
	}
	
	@override
	int arity() {
		return _stmt.params.length;
	}

	@override
	Object call(Interpreter interpreter, List<Object> args) {
		Environment env = new Environment(_closure);

		for (int i = 0; i < _stmt.params.length; i++) {
			env.define(_stmt.params[i].lexeme, args[i]);
		}

		try {
			interpreter.executeBlock(_stmt.body, env);
		} on Return catch (ret) {
			return ret.value;
		}

		return null;
	}

	@override
	String toString() {
		return '<fn ${_stmt.name.lexeme}>';
	}
}