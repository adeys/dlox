import './expr.dart';
import './tokens.dart';
import './error.dart';
import 'lox.dart';

class Interpreter implements Visitor {

	void interpret(Expr expression) {
		try {
			Object value = _evaluate(expression);
			print(_stringify(value));
		} on RuntimeError catch (e) {
			Lox.runtimeError(e);
		}
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

	Object _evaluate(Expr expr) {
		return expr.accept(this);
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
					return (left as double) < (left as double);
				}
			case TokenType.LESS_EQUAL: {
					_checkNumOperands(expr.op, left, right);
					return (left as double) <= (left as double);
				}
			case TokenType.GREATER_EQUAL: {
					_checkNumOperands(expr.op, left, right);
					return (left as double) >= (left as double);
				}
			case TokenType.GREATER: {
					_checkNumOperands(expr.op, left, right);
					return (left as double) > (left as double);
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
}