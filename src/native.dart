
import 'env.dart';
import 'interpreter.dart';
import 'struct.dart';

class NativeFunction implements LoxCallable {
	Function callable;
	int _arity = -1;

	NativeFunction(Function callable, int arity) {
		this.callable = callable;
		_arity = arity;
	}

	Object callFn(Interpreter interpreter, List<Object> args) {
		return callable(interpreter, args);
	}

	int arity() {return _arity;}

	@override
	String toString() {
		return '<native fn>';
	}

  @override
  LoxCallable bind(LoxInstance instance) {
    return this;
  }

  bool isGetter() {
    return _arity == -1;
  }
}

class NativeClass extends LoxClass implements LoxCallable {
  final String _name;

  NativeClass(String name): _name = name, super(name, null, {}, {});

  LoxCallable findMethod(String name) {
    return methods.containsKey(name) ? methods[name] : null;
  }
  
}

class NativeMethod extends NativeFunction {
  Environment _env;

  NativeMethod(Function callable, Environment env, int arity) : 
    _env = env, super(callable, arity);

  @override
  LoxCallable bind(LoxInstance instance) {
		Environment env = new Environment(_env);
		env.define('this', instance);
		return new NativeMethod(callable, env, _arity);
  }

  @override
  Object callFn(Interpreter interpreter, List<Object> args) {
    _env.parent = interpreter.env;
    interpreter.env = _env;

		var result = super.callFn(interpreter, args);

    interpreter.env = interpreter.env.parent;
    return result;
  }
}