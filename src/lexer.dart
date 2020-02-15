import 'lox.dart';
import 'tokens.dart';

class Lexer {
	final String source;
	List<Token> tokens = [];
	int start = 0;
	int current = 0;
	int line = 1;

	static final Map<String, TokenType> keywords = {
		"and": TokenType.AND,
		"or": TokenType.OR,
		"class": TokenType.CLASS,
		"super": TokenType.SUPER,
		"this": TokenType.THIS,
		"true": TokenType.TRUE,
		"false": TokenType.FALSE,
		"nil": TokenType.NIL,
		"for": TokenType.FOR,
		"while": TokenType.WHILE,
		"break": TokenType.BREAK,
		"if": TokenType.IF,
		"else": TokenType.ELSE,
		"return": TokenType.RETURN,
		"print": TokenType.PRINT,
		"let": TokenType.VAR,
		"fun": TokenType.FUN,
    "import": TokenType.IMPORT
	};

	Lexer(this.source);

	List<Token> tokenize() {
		while(!eof()) {
			start = current;
			_getNext();
		}

		this.tokens.add(new Token(TokenType.EOF, "", null, line));
		return this.tokens;
	}

	void _getNext() {
		var char = _advance();
		switch (char) {
			// Single character tokens
			case '(': addToken(TokenType.LEFT_PAREN, null); break;
			case ')': addToken(TokenType.RIGHT_PAREN, null); break;
			case '{': addToken(TokenType.LEFT_BRACE, null); break;
			case '}': addToken(TokenType.RIGHT_BRACE, null); break;
			case ',': addToken(TokenType.COMMA, null); break;
			case '.': addToken(TokenType.DOT, null); break;
			case ';': addToken(TokenType.SEMICOLON, null); break;
			case '+': addToken(TokenType.PLUS, null); break;
			case '-': addToken(TokenType.MINUS, null); break;
			case '*': addToken(TokenType.STAR, null); break;
			case '/': {
					if (_match('/')) {
						while(_peek() != '\n' && !eof()) _advance();
					} else if (_match('*')) {
						_getMultiLineComment();
					} else {
						addToken(TokenType.SLASH, null); 
					}
					break;
				}
			case '?': addToken(TokenType.QMARK, null); break;
			case ':': addToken(TokenType.COLON, null); break;
			// One or two characters tokens
			case '!': addToken(_match('=') ? TokenType.BANG_EQUAL : TokenType.BANG, null); break;
			case '=': addToken(_match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL, null); break;
			case '<': addToken(_match('=') ? TokenType.LESS_EQUAL : TokenType.LESS, null); break;
			case '>': addToken(_match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER, null); break;
			// Whitespaces
			case ' ':
			case '\t':
			case '\r': 
				break;
			case '\n':
				line++;
				break;
			// Literals
			case '"': _getString(); break;
			default:
				if (_isDigit(char)) {
					_getNumber();
				} else if (_isAlpha(char)) {
					_getIdentifier();
				} else {
					Lox.error(line, 'Unexpected character $char');
					break;
				}
		}
	}

	void _getString() {
		while(_peek() != '"' && !eof()) {
			if (_peek() == '\n') line++;
			_advance();
		}

		if (eof()) {
			Lox.error(line, 'Unterminated string.');
			return;
		}

		_advance();

		addToken(TokenType.STRING, source.substring(start + 1, current - 1));
	}

	void _getNumber() {
		while(_isDigit(_peek())) _advance();

		if (_peek() == '.' && _isDigit(_peekNext())) {
			_advance();

			while(_isDigit(_peek())) _advance();
		}

		addToken(TokenType.NUMBER, double.parse(source.substring(start, current)));
	}

	void _getIdentifier() {
		while(_isAlphaNumeric(_peek())) _advance();

		var token = source.substring(start, current);

		TokenType type = keywords[token];
		if (type == null) type = TokenType.IDENTIFIER;

		addToken(type, null);
	}

	void _getMultiLineComment() {
		while (!eof() && _peek() != '*') {
			if (_peek() == '\n') line++;
			_advance();
		}

		if (eof()) {
			Lox.error(line, 'Unterminated multi line comment section.');
			return;
		}

		_advance();
		if (_peek() == '/') {
			_advance();
			return;
		}

		_getMultiLineComment();
	}

	void addToken(TokenType type, Object literal) {
		var token = new Token(type, source.substring(start, current), literal, line);
		tokens.add(token);
	}

	String _advance() {
		current++;
		return source[current - 1];
	}

	String _peek() {
		return eof() ? '' : source[current];
	}

	String _peekNext() {
		if (current + 1 >= source.length) return '';
		
		return source[current + 1];
	}

	bool _match(String expected) {
		if (eof()) return false;

		if (_peek() != expected) return false;

		current++;
		return true;
	}

	bool eof() {
		return current >= source.length;
	}

	bool _isDigit(String char) {
		return RegExp('[0-9]').hasMatch(char);
	}

	bool _isAlpha(String char) {
		return RegExp('[a-zA-Z_]').hasMatch(char);
	}

	bool _isAlphaNumeric(String char) {
		return _isAlpha(char) || _isDigit(char);
	}
}
