import 'dart:collection';

import 'expr.dart';
import 'interpreter.dart';
import 'lox.dart';
import 'stmt.dart';
import 'tokens.dart';

enum FunctionType {
	NONE,
	FUNCTION
}

class Resolver implements ExprVisitor, StmtVisitor {
	final Interpreter _interpreter;
	ListQueue<HashMap<String, bool>> _scopes = new ListQueue();
	FunctionType _currentFunc = FunctionType.NONE; 

	Resolver(Interpreter interpreter): _interpreter = interpreter;

	void resolve(List<Stmt> stmts) {
		for (Stmt stmt in stmts) {
			_resolve(stmt);
		}
	}

	void _define(Token token) {
		if (_scopes.isEmpty) return;

		_scopes.first[token.lexeme] = true;
	}

	void _declare(Token token) {
		if (_scopes.isEmpty) return;

		Map<String, bool> scope = _scopes.first;

		if (scope.containsKey(token.lexeme)) {
			Lox.error(token.line, "Variable with this name already declared in this scope.");
		}

		_scopes.first[token.lexeme] = false;
	}

	void _resolve(dynamic stmt) {
		stmt.accept(this);
	}

	void _resolveLocal(Expr expr, Token name) {
		for (int i = 0; i < _scopes.length; i++) {
			if (_scopes.elementAt(i).containsKey(name.lexeme)) {
				_interpreter.resolve(expr, i);
				return; 
			}
		}
	}

	void _resolveFunction(FunctionStmt stmt, FunctionType type) {
		FunctionType enclosing = _currentFunc;
		_currentFunc = type;

		_beginScope();
		for (Token param in stmt.params) {
			_declare(param);
			_define(param);
		}
		resolve(stmt.body);
		_endScope();

		_currentFunc = enclosing;
	}

	void _beginScope() {
		_scopes.addFirst(new HashMap<String, bool>());
	}

	void _endScope() {
		_scopes.removeFirst();
	}

	@override
	void visitAssignExpr(AssignExpr expr) {
		_resolve(expr.value);
		_resolveLocal(expr, expr.name);
		return null;
	}

	@override
	void visitBinaryExpr(BinaryExpr expr) {
		return null;
	}

	@override
	void visitBlockStmt(BlockStmt stmt) {
		_beginScope();
		resolve(stmt.statements);
		_endScope();

		return null;
	}

	@override
	void visitCallExpr(CallExpr expr) {
		_resolve(expr.callee);
		for (Expr arg in expr.arguments) {
			_resolve(arg);
		}

		return null;
	}

	@override
	void visitExpressionStmt(ExpressionStmt stmt) {
		_resolve(stmt.expression);
		return null;
	}

	@override
	void visitFunctionStmt(FunctionStmt stmt) {
		_declare(stmt.name);
		_define(stmt.name);

		_resolveFunction(stmt, FunctionType.FUNCTION);
		return null;
	}

	@override
	void visitGroupingExpr(GroupingExpr expr) {
		_resolve(expr.expr);
		return null;
	}

	@override
	void visitIfStmt(IfStmt stmt) {
		_resolve(stmt.condition);
		_resolve(stmt.thenStmt);
		if (stmt.elseStmt != null) _resolve(stmt.elseStmt);

		return null;
	}

	@override
	void visitLiteralExpr(LiteralExpr expr) {
		return null;
	}

	@override
	void visitLogicalExpr(LogicalExpr expr) {
		_resolve(expr.left);
		_resolve(expr.right);

		return null;
	}

	@override
	void visitPrintStmt(PrintStmt stmt) {
		_resolve(stmt.expression);
		return null;
	}

	@override
	void visitReturnStmt(ReturnStmt stmt) {
		if (_currentFunc == FunctionType.NONE) {
			Lox.error(stmt.keyword.line, "Cannot return from top-level code");
		}

		if (stmt.value != null) {
			_resolve(stmt.value);	
		}

		return null;
	}

	@override
	void visitUnaryExpr(UnaryExpr expr) {
		_resolve(expr.right);
		return null;
	}

	@override
	void visitVarStmt(VarStmt stmt) {
		_declare(stmt.name);
		if (stmt.initializer != null) _resolve(stmt.initializer);
		_define(stmt.name);
		return null;
	}

	@override
	void visitVariableExpr(VariableExpr expr) {
		if (_scopes.isNotEmpty && _scopes.first[expr.name.lexeme] == false) {
			Lox.error(expr.name.line, "Cannot read local variable in its own initializer.");
		}

		_resolveLocal(expr, expr.name);
		return null;
	}

	@override
	void visitWhileStmt(WhileStmt stmt) {
		_resolve(stmt.condition);
		_resolve(stmt.body);

		return null;
	}
}