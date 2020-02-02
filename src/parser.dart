import './tokens.dart';
import './expr.dart';
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
			if (_match([TokenType.VAR])) return _getVarDeclaration();

			return _getStatement();
		} on ParseError catch (_) {
			_synchronize();
			return null;
		}
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
		if (_match([TokenType.WHILE])) return _getWhileStatement();
		if (_match([TokenType.LEFT_BRACE])) return new BlockStmt(_getBlockStatement());

		return _getExprStatement();
	}

	PrintStmt _getPrintStatement() {
		Expr expr = _getExpression();
		_consume(TokenType.SEMICOLON, "Expect ';' after value.");

		return new PrintStmt(expr);
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
		Expr expr = _getOr();

		if (_match([TokenType.EQUAL])) {
			Token equals = _previous();

			if (expr is VariableExpr) {
				Expr value = _getAssignment();
				return new AssignExpr(expr.name, value);
			}

			error(equals, "Invalid assignment target.");
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

		return _getPrimary();
	}

	Expr _getPrimary() {
		if (_match([TokenType.TRUE])) return new LiteralExpr(true);
		if (_match([TokenType.FALSE])) return new LiteralExpr(false);
		if (_match([TokenType.NIL])) return new LiteralExpr(null);

		if (_match([TokenType.NUMBER, TokenType.STRING])) {
			return new LiteralExpr(_previous().literal);
		}

		if (_match([TokenType.IDENTIFIER])) {
			return new VariableExpr(_previous());
		}

		if (_match([TokenType.LEFT_PAREN])) {
			Expr expr = _getExpression();
			_consume(TokenType.RIGHT_BRACE, 'Expected ")" after expression');

			return new GroupingExpr(expr);
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