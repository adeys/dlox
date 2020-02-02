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

		LiteralExpr expr = null;
		if (_match([TokenType.EQUAL])) {
			expr = _getExpression();
		}

		_consume(TokenType.SEMICOLON, "Expected ';' after variable declaration.");
		return new VarStmt(id, expr);
	}

	Stmt _getStatement() {
		if (_match([TokenType.PRINT])) return _getPrintStatement();

		return _getExprStatement();
	}

	PrintStmt _getPrintStatement() {
		Expr expr = _getExpression();
		_consume(TokenType.SEMICOLON, "Expect ';' after value.");

		return new PrintStmt(expr);
	}

	ExpressionStmt _getExprStatement() {
		Expr expr = _getExpression();
		_consume(TokenType.SEMICOLON, "Expect ';' after expression.");

		return new ExpressionStmt(expr);
	}

	Expr _getExpression() {
		return _getEquality();
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
			return new LiteralExpr(_previous());
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