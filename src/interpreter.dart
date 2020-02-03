import 'dart:collection';

import './expr.dart';
import './tokens.dart';
import './error.dart';
import 'env.dart';
import 'lox.dart';
import 'stmt.dart';
import 'struct.dart';

class Interpreter implements ExprVisitor, StmtVisitor {
	final Environment globals = new Environment(null);
	Environment _env;
	final Map<Expr, int> _locals = new HashMap<Expr, int>();

	Interpreter() {
		globals.define('clock', new NativeFunction((Interpreter interpreter, List<Object> args) {
			return DateTime.now().millisecondsSinceEpoch/1000;
		}, 0));

		_env = globals;
	}

	void interpret(List<Stmt> statements) {
		try {
			for (Stmt stmt in statements) {
				_execute(stmt);
			}
		} on RuntimeError catch (e) {
			Lox.runtimeError(e);
		}
	}

	void resolve(Expr expr, int depth) {
		_locals[expr] = depth;
	}

	void _execute(Stmt stmt) {
		stmt.accept(this);
	}

	Object _evaluate(Expr expr) {
		return expr.accept(this);
	}

	String _stringify(Object object) {
		if (object == null) return "nil";
		// Hack. Work around Java adding ".0" to integer-valued doubles.
		if (object is double) {
			String text = object.toString();
			if (text.endsWith(".0")) {
				text = text.substring(0, text.length - 2);
			}
			return text;
		} 
		
		return object.toString();
	}

	void executeBlock(List<Stmt> statements, Environment env) {
		Environment prev = _env;

		try {
			_env = env;
			for (Stmt stmt in statements) {
				_execute(stmt);
			}
		} finally {
			_env = prev;
		}
	}

	@override
	Object visitBinaryExpr(BinaryExpr expr) {
		Object left = _evaluate(expr.left);
		Object right = _evaluate(expr.right);

		switch (expr.op.type) {
			case TokenType.EQUAL_EQUAL: return _isEqual(left, right);
			case TokenType.BANG_EQUAL: return !_isEqual(left, right);
			case TokenType.LESS: {
					_checkNumOperands(expr.op, left, right);
					return (left as double) < (right as double);
				}
			case TokenType.LESS_EQUAL: {
					_checkNumOperands(expr.op, left, right);
					return (left as double) <= (right as double);
				}
			case TokenType.GREATER_EQUAL: {
					_checkNumOperands(expr.op, left, right);
					return (left as double) >= (right as double);
				}
			case TokenType.GREATER: {
					_checkNumOperands(expr.op, left, right);
					return (left as double) > (right as double);
				}
			case TokenType.MINUS: {
					_checkNumOperands(expr.op, left, right);
					return (left as double) - (right as double);
				}
			case TokenType.STAR: {
					_checkNumOperands(expr.op, left, right);
					return (left as double) * (right as double);
				}
			case TokenType.PLUS: {
				if (left is double) {
					return left + (right as double);
				}
				if (left is String) {
					return left + (right is String ? right : _stringify(right));
				} else if (right is String) {
					return right + (left is String ? left : _stringify(left));
				}
				throw new RuntimeError(expr.op, "Operands must be two numbers or two strings.");
			}
			case TokenType.SLASH: {
				_checkNumOperands(expr.op, left, right);
				if (right == 0) 
					throw new RuntimeError(expr.op, "Cannot divide by zero.");
					
				return (left as double) / (right as double);
			}
			default:
				break;
		}

		throw new Exception("Should never be reached");
	}

	@override
	Object visitGroupingExpr(GroupingExpr expr) {
		return _evaluate(expr.expr);
	}

	@override
	Object visitLiteralExpr(LiteralExpr expr) {
		return expr.value;
	}

	@override
	Object visitUnaryExpr(UnaryExpr expr) {
		Object right = _evaluate(expr.right);

		switch (expr.op.type) {
			case TokenType.MINUS:{
				_checkNumOperand(expr.op, right);
				return -(right as double);
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
		if (value is double) return;
		throw new RuntimeError(token, "Operand must be a number.");
	}

	void _checkNumOperands(Token token, Object left, Object right) {
		if (left is double && right is double) return;
		throw new RuntimeError(token, "Operands must be numbers.");
	}

	@override
	void visitExpressionStmt(ExpressionStmt stmt) {
		_evaluate(stmt.expression);
		return null;
	}

	@override
	void visitPrintStmt(PrintStmt stmt) {
		Object val = _evaluate(stmt.expression);
		print(_stringify(val));
		return null;
	}

	@override
	void visitVarStmt(VarStmt expr) {
		Object value = null;

		if (expr.initializer != null) {
			value = _evaluate(expr.initializer);
		}

		_env.define(expr.name.lexeme, value);
	}

	@override
	Object visitVariableExpr(VariableExpr expr) {
		return _lookupVariable(expr.name, expr);
	}

	Object _lookupVariable(Token name, Expr expr) {
		int dist = _locals[expr];
		if (dist != null) {
			return _env.getAt(dist, name.lexeme);
		} else {
			return _env.get(name);
		}
	}

	@override
	Object visitAssignExpr(AssignExpr expr) {
		Object value = _evaluate(expr.value);

		int dist = _locals[expr];
		if (dist != null) {
			_env.assignAt(dist, expr.name, value);
		} else {
			globals.assign(expr.name, value);
		}
		return value;
	}

	@override
	void visitBlockStmt(BlockStmt expr) {
		executeBlock(expr.statements, new Environment(_env));

		return null;
	}

	@override
	Object visitIfStmt(IfStmt expr) {
		if (_isTruthy(_evaluate(expr.condition))) {
			_execute(expr.thenStmt);
		} else if (expr.elseStmt != null) {
			_execute(expr.elseStmt);
		}

		return null;
	}

	@override
	Object visitLogicalExpr(LogicalExpr expr) {
		Object left = _evaluate(expr.left);
		if (expr.opt.type == TokenType.OR) {
			if (_isTruthy(left)) return left;
		} else {
			if (!_isTruthy(left)) return left;
		} 
		
		return _evaluate(expr.right);
	}

	@override
	void visitWhileStmt(WhileStmt expr) {
		while(_isTruthy(_evaluate(expr.condition))) {
			_execute(expr.body);
		}

		return null;
	}

	@override
	Object visitCallExpr(CallExpr expr) {
		Object callee = _evaluate(expr.callee);

		List<Object> args = expr.arguments.map((arg) => _evaluate(arg)).toList();

		if (!(callee is LoxCallable)) {
			throw new RuntimeError(expr.paren, "Can only call functions and classes.");
		}

		LoxCallable function = callee as LoxCallable;
		if (args.length != function.arity()) {
			throw new RuntimeError(expr.paren, "Expected ${function.arity()} arguments but got ${args.length}.");
		}

		return function.call(this, args);
	}

	@override
	visitFunctionStmt(FunctionStmt stmt) {
		LoxFunction func = new LoxFunction(stmt, _env);
		_env.define(stmt.name.lexeme, func);
		return null;
	}

	@override
	void visitReturnStmt(ReturnStmt expr) {
		Object value = null;
		if (expr.value != null) value = _evaluate(expr.value);

		throw new Return(value);
	}
}