import 'dart:collection';
import 'dart:io';

import 'expr.dart';
import 'interpreter.dart';
import 'lox.dart';
import 'stmt.dart';
import 'tokens.dart';

enum FunctionType {
	NONE,
	FUNCTION,
	INITIALIZER,
	METHOD
}

enum ClassType {
	NONE,
	CLASS,
	SUBCLASS
}

enum LoopType {
	NONE,
	LOOP
}

class Resolver implements ExprVisitor, StmtVisitor {
  final String _baseDir;
  final String _coreLibDir = File.fromUri(Platform.script).parent.absolute.path + '/lib';
	final Interpreter _interpreter;
	ListQueue<HashMap<String, bool>> _scopes = new ListQueue();
	FunctionType _currentFunc = FunctionType.NONE;
	ClassType _currentClass = ClassType.NONE;
	LoopType _currentLoop = LoopType.NONE;

	Resolver(Interpreter interpreter, String baseDir): _interpreter = interpreter, _baseDir = baseDir;

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
			Lox.error(token.line, "Variable with this name ('${token.lexeme}') already declared in this scope.");
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
		_resolve(expr.left);
		_resolve(expr.right);
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
			if (_currentFunc == FunctionType.INITIALIZER) {
				Lox.error(stmt.keyword.line, 'Cannot return a value from class constructor.');
			}
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
		LoopType enclosing = _currentLoop;
		_currentLoop = LoopType.LOOP;
		
		_resolve(stmt.condition);
		_resolve(stmt.body);

		_currentLoop = enclosing;
		return null;
	}

	@override
	void visitClassStmt(ClassStmt stmt) {
		ClassType enclosing = _currentClass;
		_currentClass = ClassType.CLASS;

		_declare(stmt.name);
		_define(stmt.name);

		if (stmt.superclass != null && stmt.name.lexeme == stmt.superclass.name.lexeme) {
			Lox.error(stmt.superclass.name.line, "A class cannot inherit from itself.");
		}

		if (stmt.superclass != null) {
			_currentClass = ClassType.SUBCLASS;
			_resolve(stmt.superclass);
		}

		if (stmt.superclass != null) {
			_beginScope();
			_scopes.first['super'] = true;
		}

		_beginScope();
		_scopes.first['this'] = true;

		for (FunctionStmt method in stmt.methods) {
			FunctionType decl = FunctionType.METHOD;
			if (method.name.lexeme ==  'construct') decl = FunctionType.INITIALIZER;
			_resolveFunction(method, decl);
		}

		_endScope();
		
		if (stmt.superclass != null) {
			_endScope();
		}

		_currentClass = enclosing;
		return null;
	}

	@override
	void visitGetExpr(GetExpr expr) {
		_resolve(expr.object);
		return null;
	}

	@override
	void visitSetExpr(SetExpr expr) {
		_resolve(expr.value);
		_resolve(expr.object);
		return null;
	}

	@override
	void visitThisExpr(ThisExpr expr) {
		if (_currentClass == ClassType.NONE) {
			Lox.error(expr.keyword.line, "Cannot use 'this' outside of a class.");
			return null;
		}

		_resolveLocal(expr, expr.keyword);
		return null;
	}

	@override
	void visitSuperExpr(SuperExpr expr) {
		if (_currentClass == ClassType.NONE) {
			Lox.error(expr.keyword.line, "Cannot use 'super' outside of a class.");
		} else if (_currentClass != ClassType.SUBCLASS) {
			Lox.error(expr.keyword.line, "Cannot use 'super' in a class with no superclass.");
		}

		_resolveLocal(expr, expr.keyword);
		return null;
	}

	@override
	void visitTernaryExpr(TernaryExpr expr) {
		_resolve(expr.condition);
		_resolve(expr.left);
		_resolve(expr.right);
		return null;
	}

	@override
	void visitBreakStmt(BreakStmt stmt) {
		if (_currentLoop != LoopType.LOOP) {
			Lox.error(stmt.keyword.line, "Cannot break outside from a loop context.");
		}

		return null;
	}

	@override
	void visitLambdaExpr(LambdaExpr expr) {
		_resolve(expr.func);
		_resolveLocal(expr, expr.name);
		return null;
	}

  @override
  void visitImportStmt(ImportStmt stmt) {
    String target = stmt.target.value;
    bool isCore = false;

    if (!target.startsWith('lox:')) {
      target = _baseDir + (target.startsWith('/') ? target : '/' + target);
    } else {
      isCore = true;
      target = target.split(':')[1];
      target = "$_coreLibDir/$target.lox";
    }
    
    File file = new File(target);
    if (!file.existsSync()) {
      Lox.error(stmt.keyword.line, "${isCore ? 'Library' : 'File'} '${stmt.target.value}' not found.");
    }
    
    stmt.target.value = target;

    return null;
  }
}