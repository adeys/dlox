import 'dart:collection';

import 'env.dart';
import 'error.dart';
import 'interpreter.dart';
import 'stmt.dart';
import 'tokens.dart';

abstract class LoxCallable {

	Object callFn(Interpreter interpreter, List<Object> args);

	int arity();
}

class NativeFunction implements LoxCallable {
	Function callable;
	int _arity = -1;

	NativeFunction(Function callable, int arity) {
		this.callable = callable;
		_arity = arity;
	}

	Object callFn(Interpreter interpreter, List<Object> args) {;
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
	final bool _isInit;
  final bool _isStatic;

	LoxFunction(FunctionStmt stmt, Environment env, bool isInit, bool isStatic): 
		_stmt = stmt, _closure = env, _isInit = isInit, _isStatic = isStatic {
		
	}
	
	@override
	int arity() {
		return _stmt.params.length;
	}

	@override
	Object callFn(Interpreter interpreter, List<Object> args) {
		Environment env = new Environment(_closure);

		for (int i = 0; i < _stmt.params.length; i++) {
			env.define(_stmt.params[i].lexeme, args[i]);
		}

		try {
			interpreter.executeBlock(_stmt.body, env);
		} on Return catch (ret) {
			if (_isInit) return _closure.getAt(0, 'this');
			return ret.value;
		}

		if (_isInit) return _closure.getAt(0, 'this');
		return null;
	}

	LoxFunction bind(LoxInstance instance) {
		Environment env = new Environment(_closure);
		env.define('this', instance);
		return new LoxFunction(_stmt, env, _isInit, _isStatic);
	}

	@override
	String toString() {
		return '<fn ${_stmt.name.lexeme}>';
	}
}

class LoxClass extends LoxInstance implements LoxCallable {
	final String _name;
	Map<String, LoxFunction> methods = new HashMap();
  final LoxClass _parent;

	LoxClass(String name, LoxClass parent, Map<String, LoxFunction> _methods): 
    _name = name, _parent = parent, methods = _methods, super(null) {
      super._class = this;
    }

	LoxFunction findMethod(String name) {
		if (methods.containsKey(name)) {
			return methods[name];
		}

		if (_parent != null) {
			return _parent.findMethod(name);
		}

		return null;
	}

	@override
	String toString() {
		return '<class $_name>';
	}

	@override
	int arity() {
		LoxFunction init = findMethod('construct');
		if (init == null) return 0;
		return init.arity();
	}

	@override
	LoxInstance callFn(Interpreter interpreter, List<Object> args) {
		LoxInstance instance = new LoxInstance(this);
		LoxFunction init = findMethod('construct');
		if (init != null) {
			init.bind(instance).callFn(interpreter, args);
		}

		return instance;
	}

  Object get(Token field) {
    Object val = super.get(field);

    if (val is LoxFunction && !val._isStatic) {
      throw new RuntimeError(field, "Cannot call non-static method from class object.");
    }

    return val;
  }

  void set(Token name, Object value) {
    throw new RuntimeError(name, "Cannot set field on class object.");
  }
}

class LoxInstance {
	LoxClass _class;
	final Map<String, Object> _fields = new HashMap();

	LoxInstance(LoxClass klass): _class = klass;

	Object get(Token field) {
		if (_fields.containsKey(field.lexeme)) {
			return _fields[field.lexeme];
		}

		LoxFunction method = _class.findMethod(field.lexeme);
		if (method != null) return method.bind(this);

		throw new RuntimeError(field, "Undefined property '${field.lexeme}'.");
	}

	void set(Token name, Object value) {
		_fields[name.lexeme] = value;
	}

	@override
	String toString() {
		return '$_class instance';
	}
}