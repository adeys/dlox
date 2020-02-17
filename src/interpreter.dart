import 'dart:collection';
import 'dart:io';

import 'error_reporter.dart';
import 'expr.dart';
import 'module.dart';
import 'parser.dart';
import 'resolver.dart';
import 'std/core.dart';
import 'tokens.dart';
import 'error.dart';
import 'env.dart';
import 'stmt.dart';
import 'struct.dart';

class Interpreter implements ExprVisitor, StmtVisitor {
	final Environment globals = new Environment(null);
	final Map<Expr, int> _locals = new HashMap<Expr, int>();
	Environment env = new Environment(null);
  Map<String, LoxModule> modules =  {};
  Map<String, LoxCallable> natives =  {};
  LoxModule currentModule;

	Interpreter() {
		registerStdLib(this);

		env = globals;
	}

  void registerNative(String name, LoxCallable) {
    natives[name] = LoxCallable;
  }

	Object interpret(LoxModule module) {
		Object result;
    LoxModule old = currentModule;
    currentModule = module;

		Resolver resolver = new Resolver(this);
		resolver.resolve(module.statements);

		if (ErrorReporter.hadError) exit(65);

    modules[module.name] = module;

		try {
			for (Stmt stmt in module.statements) {
				result = _execute(stmt);
        if (ErrorReporter.hadRuntimeError) exit(70);
			}
		} on RuntimeError catch (e) {
			ErrorReporter.runtimeError(e);
		} on Throw catch (e) {
      print('Runtime Exception: ${e.value}');
    } on Exit catch(e) {
      exit(e.value);
    }

    currentModule = old;
		return result;
	}

	void resolve(Expr expr, int depth) {
		_locals[expr] = depth;
	}

	Object _execute(Stmt stmt) {
		return stmt.accept(this);
	}

	Object evaluate(Expr expr) {
		return expr.accept(this);
	}

	String stringify(Object object) {
		if (object == null) return "nil";
		// Hack. Work around Java adding ".0" to integer-valued doubles.
		if (object is num) {
			String text = object.toString();
			if (text.endsWith(".0")) {
				text = text.substring(0, text.length - 2);
			}
			return text;
		} 
		
		return object.toString();
	}

	void executeBlock(List<Stmt> statements, Environment _env) {
		Environment prev = env;

		try {
			env = _env;
			for (Stmt stmt in statements) {
				_execute(stmt);
			}
		} finally {
			env = prev;
		}
	}

	@override
	Object visitBinaryExpr(BinaryExpr expr) {
		Object left = evaluate(expr.left);
		Object right = evaluate(expr.right);

		switch (expr.op.type) {
			case TokenType.EQUAL_EQUAL: return _isEqual(left, right);
			case TokenType.BANG_EQUAL: return !_isEqual(left, right);
			case TokenType.LESS: {
					_checkNumOperands(expr.op, left, right);
					return (left as num) < (right as num);
				}
			case TokenType.LESS_EQUAL: {
					_checkNumOperands(expr.op, left, right);
					return (left as num) <= (right as num);
				}
			case TokenType.GREATER_EQUAL: {
					_checkNumOperands(expr.op, left, right);
					return (left as num) >= (right as num);
				}
			case TokenType.GREATER: {
					_checkNumOperands(expr.op, left, right);
					return (left as num) > (right as num);
				}
			case TokenType.MINUS: {
					_checkNumOperands(expr.op, left, right);
					return (left as num) - (right as num);
				}
			case TokenType.STAR: {
					_checkNumOperands(expr.op, left, right);
					return (left as num) * (right as num);
				}
			case TokenType.PLUS: {
				if (left is num) {
					return left + (right as num);
				} else if (left is String || right is String) {
					return stringify(left) + stringify(right);
				}
        
				throw new RuntimeError(expr.op, "Operands must be two numbers or two strings.");
			}
			case TokenType.SLASH: {
				_checkNumOperands(expr.op, left, right);
				if (right == 0) 
					throw new RuntimeError(expr.op, "Cannot divide by zero.");
					
				return (left as num) / (right as num);
			}
			default:
				break;
		}

		throw new Exception("Should never be reached");
	}

	@override
	Object visitGroupingExpr(GroupingExpr expr) {
		return evaluate(expr.expr);
	}

	@override
	Object visitLiteralExpr(LiteralExpr expr) {
		return expr.value;
	}

	@override
	Object visitUnaryExpr(UnaryExpr expr) {
		Object right = evaluate(expr.right);

		switch (expr.op.type) {
			case TokenType.MINUS:{
				_checkNumOperand(expr.op, right);
				return -(right as num);
			}
			case TokenType.BANG: return !_isTruthy(right);
			default: break;
		}

		return null;
	}

	bool _isTruthy(Object value) {
		if (value == null) return false;
		if (value is bool) return value;

		return true;
	}

	bool _isEqual(Object a, Object b) {
		if (a == null && b == null) return true;
		if (a == null) return false;
		return a == b;
	}

	void _checkNumOperand(Token token, Object value) {
		if (value is num) return;
		throw new RuntimeError(token, "Operand must be a number.");
	}

	void _checkNumOperands(Token token, Object left, Object right) {
		if (left is num && right is num) return;
		throw new RuntimeError(token, "Operands must be numbers.");
	}

	@override
	Object visitExpressionStmt(ExpressionStmt stmt) {
		return evaluate(stmt.expression);
	}

	@override
	void visitPrintStmt(PrintStmt stmt) {
		Object val = evaluate(stmt.expression);
		print(stringify(val));
		return null;
	}

	@override
	void visitVarStmt(VarStmt expr) {
		Object value = null;

		if (expr.initializer != null) {
			value = evaluate(expr.initializer);
		}

		env.define(expr.name.lexeme, value);
	}

	@override
	Object visitVariableExpr(VariableExpr expr) {
		return _lookupVariable(expr.name, expr);
	}

	Object _lookupVariable(Token name, Expr expr) {
		int dist = _locals[expr];
		if (dist != null) {
			return env.getAt(dist, name.lexeme);
		} else {
			return env.get(name);
		}
	}

	@override
	Object visitAssignExpr(AssignExpr expr) {
		Object value = evaluate(expr.value);

		int dist = _locals[expr];
		if (dist != null) {
			env.assignAt(dist, expr.name, value);
		} else {
			globals.assign(expr.name, value);
		}
		return value;
	}

	@override
	void visitBlockStmt(BlockStmt expr) {
		executeBlock(expr.statements, new Environment(env));

		return null;
	}

	@override
	Object visitIfStmt(IfStmt expr) {
		if (_isTruthy(evaluate(expr.condition))) {
			_execute(expr.thenStmt);
		} else if (expr.elseStmt != null) {
			_execute(expr.elseStmt);
		}

		return null;
	}

	@override
	Object visitLogicalExpr(LogicalExpr expr) {
		Object left = evaluate(expr.left);
		if (expr.opt.type == TokenType.OR) {
			if (_isTruthy(left)) return left;
		} else {
			if (!_isTruthy(left)) return left;
		} 
		
		return evaluate(expr.right);
	}

	@override
	void visitWhileStmt(WhileStmt expr) {
		try {
			while(_isTruthy(evaluate(expr.condition))) {
				_execute(expr.body);
			}
		} on Break {
			return;
		}

		return null;
	}

	@override
	Object visitCallExpr(CallExpr expr) {
		Object callee = evaluate(expr.callee);

		List<Object> args = expr.arguments.map((arg) => evaluate(arg)).toList();

		if (!(callee is LoxCallable)) {
			throw new RuntimeError(expr.paren, "Can only call functions and classes.");
		}

		LoxCallable function = callee as LoxCallable;
		if (args.length != function.arity()) {
			throw new RuntimeError(expr.paren, "Expected ${function.arity()} arguments but got ${args.length}.");
		}

		return function.callFn(this, args);
	}

	@override
	Object visitFunctionStmt(FunctionStmt stmt) {
		LoxFunction func = new LoxFunction(stmt, env, false, false);
		env.define(stmt.name.lexeme, func);
		return func;
	}

	@override
	void visitReturnStmt(ReturnStmt expr) {
		Object value = null;
		if (expr.value != null) value = evaluate(expr.value);

		throw new Return(value);
	}


  void _getNativeClass(ClassStmt stmt) {
    String name = stmt.name.lexeme;
    LoxClass klass = natives[name];
    klass.isNative = true;

    for (FunctionStmt method in stmt.methods) {
      if (!method.isNative) {
        LoxFunction func = new LoxFunction(method, env, method.name.lexeme == 'construct', method.isGetter);
        klass.methods[method.name.lexeme] = func;
      }
    }

    for (FunctionStmt method in stmt.staticMethods) {
      if (!method.isNative) {
        LoxFunction func = new LoxFunction(method, env, false, method.isGetter);
        klass.staticMethods[method.name.lexeme] = func;
      }
    }

    env.define(name, klass);
    return;
  }

	@override
	void visitClassStmt(ClassStmt stmt) {
		if (stmt.isNative) return _getNativeClass(stmt);
    
    Object superclass = null;
		if (stmt.superclass != null) {
			superclass = evaluate(stmt.superclass);
			if (!(superclass is LoxClass)) {
				throw new RuntimeError(stmt.superclass.name, "Superclass must be a class");
			}
		}

		env.define(stmt.name.lexeme, null);

		if (stmt.superclass != null) {
			env = new Environment(env);
			env.define('super', superclass);
		}

		Map<String, LoxCallable> methods = new HashMap();
		Map<String, LoxCallable> staticMethods = new HashMap();

		for (FunctionStmt method in stmt.methods) {
			LoxFunction func = new LoxFunction(method, env, method.name.lexeme == 'construct', method.isGetter);
			methods[method.name.lexeme] = func;
		}

    for (FunctionStmt method in stmt.staticMethods) {
			LoxFunction func = new LoxFunction(method, env, false, method.isGetter);
			staticMethods[method.name.lexeme] = func;
		}

		// Provide a default constructor to base class instance
		if (stmt.superclass == null && !methods.containsKey('construct')) {
			FunctionStmt functionStmt = new FunctionStmt(null, [], [], false);
			methods['construct'] = new LoxFunction(functionStmt, env, true, false);
		}

		LoxClass klass = new LoxClass(stmt.name.lexeme, superclass, methods, staticMethods);

		if (superclass != null) env = env.parent;

		env.assign(stmt.name, klass);

		return null;
	}

	@override
	Object visitGetExpr(GetExpr expr) {
		Object obj = evaluate(expr.object);
		if (obj is LoxInstance) {
			return obj.get(expr.name, this);
		}
		
		throw new RuntimeError(expr.name, "Only instances have properties.");
	}

	@override
	void visitSetExpr(SetExpr expr) {
		Object obj = evaluate(expr.object);

		if(!(obj is LoxInstance)) {
			throw new RuntimeError(expr.name, "Only instances have fields");
		}

		Object value = evaluate(expr.value);
		(obj as LoxInstance).set(expr.name, value);

		return null;
	}

	@override
	Object visitThisExpr(ThisExpr expr) {
		return _lookupVariable(expr.keyword, expr);
	}

	@override
	LoxFunction visitSuperExpr(SuperExpr expr) {
		int dist = _locals[expr];
		LoxClass superclass = env.getAt(dist, 'super');
		LoxInstance obj = env.getAt(dist - 1, 'this');

		LoxFunction method = superclass.findMethod(expr.method.lexeme);

		if (method == null) {
			throw new RuntimeError(expr.method, "Undefined property '${expr.method.lexeme}");
		}

		return method.bind(obj);
	}

	@override
	Object visitTernaryExpr(TernaryExpr expr) {
		if (_isTruthy(evaluate(expr.condition))) {
			return evaluate(expr.left);
		} else {
			return evaluate(expr.right);
		}
	}

	@override
	void visitBreakStmt(BreakStmt expr) {
		throw new Break();
	}

	@override
	Object visitLambdaExpr(LambdaExpr expr) {
		return _execute(expr.func);
	}

  @override
  void visitImportStmt(ImportStmt stmt) {
    if (!modules.containsKey(stmt.module.value)) {
      LoxModule module = ModuleResolver.load(stmt.module.value);

      List<Stmt> stmts = Parser.fromSource(module.source).parse();
      if (ErrorReporter.hadError) exit(75);
      
      module.statements = stmts;
      interpret(module);
    }

    return null;
  }

  @override
  visitThrowStmt(ThrowStmt stmt) {
    throw new RuntimeError(stmt.keyword, evaluate(stmt.message));
  }
}