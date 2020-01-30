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
		"if": TokenType.IF,
		"else": TokenType.ELSE,
		"return": TokenType.RETURN,
		"print": TokenType.PRINT,
	};

	Lexer(this.source);

	List<Token> tokenize() {
		while(!eof()) {
			start = current;
			getNext();
		}

		this.tokens.add(new Token(TokenType.EOF, "", null, line));
		return this.tokens;
	}

	void getNext() {
		var char = advance();
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
					if (match('/')) {
						while(peek() != '\n' && !eof()) advance();
					} else if (match('*')) {
						getMultiLineComment();
					} else {
						addToken(TokenType.SLASH, null); 
					}
					break;
				}
			// One or two characters tokens
			case '!': addToken(match('=') ? TokenType.BANG_EQUAL : TokenType.BANG, null); break;
			case '=': addToken(match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL, null); break;
			case '<': addToken(match('=') ? TokenType.LESS_EQUAL : TokenType.LESS, null); break;
			case '>': addToken(match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER, null); break;
			// Whitespaces
			case ' ':
			case '\t':
			case '\r': 
				break;
			case '\n':
				line++;
				break;
			// Literals
			case '"': getString(); break;
			default:
				if (isDigit(char)) {
					getNumber();
				} else if (isAlpha(char)) {
					getIdentifier();
				} else {
					Lox.error(line, 'Unexpected character $char');
					break;
				}
		}
	}

	void getString() {
		while(peek() != '"' && !eof()) {
			if (peek() == '\n') line++;
			advance();
		}

		if (eof()) {
			Lox.error(line, 'Unterminated string.');
			return;
		}

		advance();

		addToken(TokenType.STRING, source.substring(start + 1, current - 1));
	}

	void getNumber() {
		while(isDigit(peek())) advance();

		if (peek() == '.' && isDigit(peekNext())) {
			advance();

			while(isDigit(peek())) advance();
		}

		addToken(TokenType.NUMBER, double.parse(source.substring(start, current)));
	}

	void getIdentifier() {
		while(isAlphaNumeric(peek())) advance();

		var token = source.substring(start, current);

		TokenType type = keywords[token];
		if (type == null) type = TokenType.IDENTIFIER;

		addToken(type, null);
	}

	void getMultiLineComment() {
		while (!eof() && peek() != '*') {
			if (peek() == '\n') line++;
			advance();
		}

		if (eof()) {
			Lox.error(line, 'Unterminated multi line comment section.');
			return;
		}

		advance();
		if (peek() == '/') {
			advance();
			return;
		}

		getMultiLineComment();
	}

	void addToken(TokenType type, Object literal) {
		var token = new Token(type, source.substring(start, current), literal, line);
		tokens.add(token);
	}

	String advance() {
		current++;
		return source[current - 1];
	}

	String peek() {
		return eof() ? '' : source[current];
	}

	String peekNext() {
		if (current + 1 >= source.length) return '';
		
		return source[current + 1];
	}

	bool match(String expected) {
		if (eof()) return false;

		if (peek() != expected) return false;

		current++;
		return true;
	}

	bool eof() {
		return current >= source.length;
	}

	bool isDigit(String char) {
		return RegExp('[0-9]').hasMatch(char);
	}

	bool isAlpha(String char) {
		return RegExp('[a-zA-Z]').hasMatch(char);
	}

	bool isAlphaNumeric(String char) {
		return isAlpha(char) || isDigit(char);
	}
}
