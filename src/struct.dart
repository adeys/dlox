import 'dart:collection';

import 'env.dart';
import 'error.dart';
import 'interpreter.dart';
import 'stmt.dart';
import 'tokens.dart';

abstract class LoxCallable {

	Object callFn(Interpreter interpreter, List<Object> args);

	int arity();

  LoxCallable bind(LoxInstance instance);

  bool isGetter();
}

class LoxFunction implements LoxCallable {
	final FunctionStmt _stmt;
	final Environment _closure;
	final bool _isInit;
  final bool _isGetter;
  final bool isNative;

	LoxFunction(FunctionStmt stmt, Environment env, bool isInit, bool isGetter, [bool _native = false]): 
		_stmt = stmt, _closure = env, _isInit = isInit, _isGetter = isGetter, isNative = _native {
		
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

  @override
	LoxFunction bind(LoxInstance instance) {
		Environment env = new Environment(_closure);
		env.define('this', instance);
		return new LoxFunction(_stmt, env, _isInit, _isGetter, isNative);
	}

	@override
	String toString() {
		return '<fn ${_stmt.name.lexeme}>';
	}


  bool isGetter() {
    return _isGetter;
  }
}

class LoxClass extends LoxInstance implements LoxCallable {
	final String _name;
	Map<String, LoxCallable> methods = new HashMap();
	Map<String, LoxCallable> staticMethods = new HashMap();
  final LoxClass _parent;
  bool isNative;
  List<String> allowedFields = [];

	LoxClass(String name, LoxClass parent, Map<String, LoxCallable> _methods, Map<String, LoxCallable> _staticMethods, [bool isNative = false]): 
    _name = name, _parent = parent, methods = _methods, staticMethods = _staticMethods, super(null) {
      super._class = this;
      this.isNative = isNative;
    }

	LoxCallable findMethod(String name) {
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
		LoxCallable init = findMethod('construct');
		if (init == null) return 0;
		return init.arity();
	}

	@override
	LoxInstance callFn(Interpreter interpreter, List<Object> args) {
		LoxInstance instance = new LoxInstance(this);
		LoxCallable init = findMethod('construct');
		if (init != null) {
			init.bind(instance).callFn(interpreter, args);
		}

		return instance;
	}

  Object get(Token field, Interpreter interpreter) {
    String name = field.lexeme;

    if (staticMethods.containsKey(name)) {
      LoxCallable func = staticMethods[name].bind(this);

      return func.isGetter() ? func.callFn(interpreter, []) : func;
    }

    throw new RuntimeError(field, "Cannot call non-static method from class object.");
  }

  void set(Token name, Object value) {
    throw new RuntimeError(name, "Cannot set field on class object.");
  }

  @override
  LoxCallable bind(LoxInstance instance) {
    return this;
  }


  bool isGetter() {
    return false;
  }
}

class LoxInstance {
	LoxClass _class;
	final Map<String, Object> _fields = new HashMap();

	LoxInstance(LoxClass klass): _class = klass;

	Object get(Token field, Interpreter interpreter) {
		if (_fields.containsKey(field.lexeme)) {
			return _fields[field.lexeme];
		}

		LoxCallable method = _class.findMethod(field.lexeme);
		if (method != null) {
      method = method.bind(this);

      if (method.isGetter()) {
        return method.callFn(interpreter, []);
      }

      return method;
    }

		throw new RuntimeError(field, "Undefined property '${field.lexeme}' in class '${_class._name}'.");
	}

	void set(Token field, Object value) {
    if (_class.isNative && !_class.allowedFields.contains(field.lexeme)) {
      throw new RuntimeError(field, "Cannot set property '${field.lexeme}' on native class '${_class._name}'.");
    }

		_fields[field.lexeme] = value;
	}

	@override
	String toString() {
		return '$_class instance';
	}
}
