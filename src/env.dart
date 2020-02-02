import 'error.dart';
import 'tokens.dart';

class Environment {
	Map<String, Object> _store = new Map<String, Object>();
	Environment _parent = null;

	Environment(Environment parent) {
		_parent = parent;
	}

	void define(String name, Object value) {
		_store[name] = value;
	}

	void assign(Token name, Object value) {
		if (_store.containsKey(name.lexeme)) {
			_store[name.lexeme] =  value;
			return;
		}

		if (_parent != null) {
			_parent.assign(name, value);
			return;
		}

		throw new RuntimeError(name, "Undefined variable '${name.lexeme}'.");
	}

	Object get(Token name) {
		if (_store.containsKey(name.lexeme)) {
			return _store[name.lexeme];
		}

		if (_parent != null) return _parent.get(name);

		throw new RuntimeError(name, "Undefined variable '${name.lexeme}'.");
	}
}