import 'dart:math';

import 'tokens.dart';
import 'expr.dart';
import 'lox.dart';
import 'stmt.dart';

class Parser {
	final List<Token> _tokens;
	int _current = 0;

	Parser(this._tokens);

	List<Stmt> parse() {
		List<Stmt> statements = new List();
		while (!eof()) {
			statements.add(_getDeclaration());
		}

		return statements;
	}

	Stmt _getDeclaration() {
		try {
			if (_match([TokenType.CLASS])) return _getClassDeclaration();
			if (_match([TokenType.FUN])) return _getFuncDeclaration('function');
			if (_match([TokenType.VAR])) return _getVarDeclaration();

			return _getStatement();
		} on ParseError catch (_) {
			_synchronize();
			return null;
		}
	}

	ClassStmt _getClassDeclaration() {
		Token name = _consume(TokenType.IDENTIFIER, "Expect class name.");

		VariableExpr superclass = null;
		if (_match([TokenType.COLON])) {
			_consume(TokenType.IDENTIFIER, "Expect superclass name.");
			superclass = new VariableExpr(_previous());
		}

		_consume(TokenType.LEFT_BRACE, "Expect '{' before class body.");
		
		List<FunctionStmt> methods = [];
		while (!_check(TokenType.RIGHT_BRACE) && !eof()) {
			methods.add(_getFuncDeclaration("method"));
		} 
		
		_consume(TokenType.RIGHT_BRACE, "Expect '}' after class body.");
		return new ClassStmt(name, superclass, methods);
	}

	FunctionStmt _getFuncDeclaration(String type) {
		Token name;
		
		if (type == 'lambda') {
			var anon = '__anon_${Random().nextInt(256)}';
			name = new Token(TokenType.STRING, anon, anon, _previous().line);
		} else {
			name = _consume(TokenType.IDENTIFIER, "Expect ${type} name.");
		}

		_consume(TokenType.LEFT_PAREN, "Expect '(' after $type name.");
		List<Token> params = [];
		if (!_check(TokenType.RIGHT_PAREN)) {
			do {
				if (params.length >= 255) {
					error(_peek(), "Cannot have more than 255 parameters.");
				} 
				params.add(_consume(TokenType.IDENTIFIER, "Expect parameter name."));
			} while (_match([TokenType.COMMA]));
		}
		
		_consume(TokenType.RIGHT_PAREN, "Expect ')' after parameters.");

		_consume(TokenType.LEFT_BRACE, "Expect '{' before $type body.");
		List<Stmt> body = _getBlockStatement();

		return new FunctionStmt(name, params, body);
	}

	VarStmt _getVarDeclaration() {
		Token id = _consume(TokenType.IDENTIFIER, "Expected variable name.");

		Expr expr = null;
		if (_match([TokenType.EQUAL])) {
			expr = _getExpression();
		}

		_consume(TokenType.SEMICOLON, "Expected ';' after variable declaration.");
		return new VarStmt(id, expr);
	}

	Stmt _getStatement() {
		if (_match([TokenType.FOR])) return _getForStatement();
		if (_match([TokenType.IF])) return _getIfStatement();
		if (_match([TokenType.PRINT])) return _getPrintStatement();
		if (_match([TokenType.RETURN])) return _getReturnStatement();
		if (_match([TokenType.BREAK])) return _getBreakStatement();
		if (_match([TokenType.WHILE])) return _getWhileStatement();
		if (_match([TokenType.LEFT_BRACE])) return new BlockStmt(_getBlockStatement());

		return _getExprStatement();
	}

	PrintStmt _getPrintStatement() {
		Expr expr = _getExpression();
		_consume(TokenType.SEMICOLON, "Expect ';' after value.");

		return new PrintStmt(expr);
	}

	BreakStmt _getBreakStatement() {
		Token keyword = _previous();
		_consume(TokenType.SEMICOLON, "Expect ';' after 'break' statement.");
		return new BreakStmt(keyword);
	}

	ReturnStmt _getReturnStatement() {
		Token keyword = _previous();

		Expr val = null;
		if (!_match([TokenType.SEMICOLON])) {
			val = _getExpression();
		}

		_consume(TokenType.SEMICOLON,  "Expect ';' after return value.");

		return new ReturnStmt(keyword, val);
	}

	Stmt _getForStatement() {
		_consume(TokenType.LEFT_PAREN, "Expect '(' after 'for'.");

		Stmt init;
		if (_match([TokenType.SEMICOLON])) {
			init = null;
		} else if (_match([TokenType.VAR])) {
			init = _getVarDeclaration();
		} else {
			init = _getExprStatement();
		}
		
		Expr cond = null;
		if (!_check(TokenType.SEMICOLON)) {
			cond = _getExpression();
		}
		_consume(TokenType.SEMICOLON, "Expect ';' after loop condition.");
		
		Expr inc = null;
		if (!_check(TokenType.RIGHT_PAREN)) {
			inc = _getExpression();
		}
		_consume(TokenType.RIGHT_PAREN, "Expect ')' after for clauses.");
		
		Stmt body = _getStatement();
		
		if (inc != null) {
			body = new BlockStmt([body, new ExpressionStmt(inc)]);
		}

		if (cond == null) cond = new LiteralExpr(true);

		body = new WhileStmt(cond, body);

		if (init != null) {
			body = new BlockStmt([init, body]);
		}

		return body;
	}

	IfStmt _getIfStatement() {
		_consume(TokenType.LEFT_PAREN, "Expected '(' after 'if'.");
		Expr condition = _getExpression();
		
		_consume(TokenType.RIGHT_PAREN, "Expected ')' after if condition.");
		Stmt thenBranch = _getStatement();
		Stmt elseBranch = null;
		
		if (_match([TokenType.ELSE])) {
			elseBranch = _getStatement();
		} 
		
		return new IfStmt(condition, thenBranch, elseBranch);
	}

	WhileStmt _getWhileStatement() {
		_consume(TokenType.LEFT_PAREN, "Expect '(' after while.");
		Expr condition = _getExpression();
		
		_consume(TokenType.RIGHT_PAREN, "Expect ')' after condition.");
		Stmt body = _getStatement();
		
		return new WhileStmt(condition, body);
	}

	List<Stmt> _getBlockStatement() {
		List<Stmt> list = [];

		while (!_check(TokenType.RIGHT_BRACE) && !eof()) {
			list.add(_getDeclaration());
		}

		_consume(TokenType.RIGHT_BRACE, "Expect '}' after block.");

		return list;
	}

	ExpressionStmt _getExprStatement() {
		Expr expr = _getExpression();
		_consume(TokenType.SEMICOLON, "Expect ';' after expression.");

		return new ExpressionStmt(expr);
	}

	Expr _getExpression() {
		return _getAssignment();
	}

	Expr _getAssignment() {
		Expr expr = _getTernary();

		if (_match([TokenType.EQUAL])) {
			Token equals = _previous();

			Expr value = _getAssignment();
			if (expr is VariableExpr) {
				return new AssignExpr(expr.name, value);
			} else if (expr is GetExpr) {
				return new SetExpr(expr.object, expr.name, value);
			}

			error(equals, "Invalid assignment target.");
		}

		return expr;
	}

	Expr _getTernary() {
		Expr expr = _getOr();

		if (_match([TokenType.QMARK])) {
			Token op = _previous();

			Expr left = _getExpression();
			_consume(TokenType.COLON, "Expect ':' in ternary operator after expression.");
			Expr right = _getExpression();
			
			expr = new TernaryExpr(op, expr, left, right);
		}

		return expr;
	}

	Expr _getOr() {
		Expr expr = _getAnd();

		while (_match([TokenType.OR])) {
			Token op = _previous();
			Expr right = _getAnd();

			expr = new LogicalExpr(expr, op, right);
		}

		return expr;
	}

	Expr _getAnd() {
		Expr expr = _getEquality();

		while (_match([TokenType.AND])) {
			Token op = _previous();
			Expr right = _getEquality();

			expr = new LogicalExpr(expr, op, right);
		}

		return expr;
	}

	Expr _getEquality() {
		Expr expr = _getComparison();

		while(_match([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
			Token op = _previous();
			Expr right = _getComparison();
			expr = new BinaryExpr(expr, op, right);
		}

		return expr;
	}

	Expr _getComparison() {
		Expr expr = _getAddition();

		while(_match([TokenType.LESS, TokenType.LESS_EQUAL, TokenType.GREATER, TokenType.GREATER_EQUAL])) {
			Token op = _previous();
			Expr right = _getAddition();
			expr = new BinaryExpr(expr, op, right);
		}

		return expr;
	}

	Expr _getAddition() {
		Expr expr = _getMultiplication();

		while(_match([TokenType.MINUS, TokenType.PLUS])) {
			Token op = _previous();
			Expr right = _getMultiplication();
			expr = new BinaryExpr(expr, op, right);
		}

		return expr;
	}

	Expr _getMultiplication() {
		Expr expr = _getUnary();

		while(_match([TokenType.STAR, TokenType.SLASH])) {
			Token op = _previous();
			Expr right = _getUnary();
			expr = new BinaryExpr(expr, op, right);
		}

		return expr;
	}

	Expr _getUnary() {
		if (_match([TokenType.BANG, TokenType.MINUS])) {
			Token op = _previous();
			Expr right = _getUnary();
			return new UnaryExpr(op, right);
		}

		return _getCall();
	}

	Expr _getCall() {
		Expr expr = _getPrimary();

		while (true) {
			if (_match([TokenType.LEFT_PAREN])) {
				expr = _finishCall(expr);
			} else if (_match([TokenType.DOT])) {
				Token name = _consume(TokenType.IDENTIFIER, "Expect name property after '.'.");
				expr = new GetExpr(expr, name);
			} else {
				break;
			}
		}

		return expr;
	}

	Expr _finishCall(Expr expr) {
		List<Expr> args = [];

		if (!_check(TokenType.RIGHT_PAREN)) {
			do {
				if (args.length >= 255) error(_peek(), "Cannot have more than 255 arguments.");
				args.add(_getExpression());
			} while (_match([TokenType.COMMA]));
		}

		Token paren = _consume(TokenType.RIGHT_PAREN, "Expected ')' after arguments list.");

		return new CallExpr(expr, paren, args);
	}

	Expr _getPrimary() {
		if (_match([TokenType.TRUE])) return new LiteralExpr(true);
		if (_match([TokenType.FALSE])) return new LiteralExpr(false);
		if (_match([TokenType.NIL])) return new LiteralExpr(null);

		if (_match([TokenType.NUMBER, TokenType.STRING])) {
			return new LiteralExpr(_previous().literal);
		}

		if (_match([TokenType.THIS])) return new ThisExpr(_previous());

		if (_match([TokenType.IDENTIFIER])) {
			return new VariableExpr(_previous());
		}

		if (_match([TokenType.LEFT_PAREN])) {
			Expr expr = _getExpression();
			_consume(TokenType.RIGHT_PAREN, 'Expected ")" after expression');

			return new GroupingExpr(expr);
		}

		if (_match([TokenType.SUPER])) {
			Token keyword = _previous();
			_consume(TokenType.DOT, "Expect '.' after 'super'.");
			Token method = _consume(TokenType.IDENTIFIER, "Expect superclass method name.");
			return new SuperExpr(keyword, method);
		}

		if (_match([TokenType.FUN]) && _check(TokenType.LEFT_PAREN)) {
			FunctionStmt func = _getFuncDeclaration('lambda');
			return new LambdaExpr(func.name, func);
		}

		throw error(_peek(), 'Expected expression.');
	}

	Token _advance() {
		if (!eof()) _current++;

		return _previous();
	}

	bool _match(List<TokenType> types) {
		for (TokenType type in types) {
			if (_check(type)) {
				_advance();
				return true;
			}
		}

		return false;
	}

	Token _consume(TokenType token, String message) {
		if (_check(token)) return _advance();
    
		throw error(_peek(), message);
	}

	bool eof() {
		return _peek().type == TokenType.EOF;
	}

	bool _check(TokenType type) {
		if (eof()) return false;

		return _peek().type == type;
	}

	Token _peek() {
		return _tokens[_current];
	}

	Token _previous() {
		return _tokens[_current - 1];
	}

	void _synchronize() {
		_advance();

		while (!eof()) {
			if (_previous().type == TokenType.EOF) return;

			switch (_peek().type) {
				case TokenType.CLASS:
				case TokenType.VAR:
				case TokenType.FUN:
				case TokenType.IF:
				case TokenType.ELSE:
				case TokenType.FOR:
				case TokenType.WHILE:
				case TokenType.PRINT:
				case TokenType.RETURN:
					return;
				default:
					_advance();
			}
		}
	}

	error(Token token, String msg) {
		Lox.parseError(token, msg);

		return new ParseError();
	}
}

class ParseError extends Error {
  
}