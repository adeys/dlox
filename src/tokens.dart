enum TokenType {
	// Single character tokens
	LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
	COMMA, DOT, SEMICOLON, MINUS, PLUS, STAR, SLASH,
	QMARK, COLON,

	// One or two characters tokens
	BANG, BANG_EQUAL, EQUAL, EQUAL_EQUAL,
	GREATER, GREATER_EQUAL, LESS, LESS_EQUAL,

	// Literals
	IDENTIFIER, STRING, NUMBER,

	// Keywords
	AND, OR, CLASS, SUPER, THIS, IF, ELSE, FOR, WHILE,
	BREAK, FUN, RETURN, TRUE, FALSE, NIL, VAR, IMPORT, 
  STATIC, NATIVE,

	EOF
}

class Token {
	TokenType type;
	Object literal;
	String lexeme;
  String file;
	int line;

	Token(TokenType type, String lexeme, Object literal, String file, int line) {
		this.type = type;
		this.literal = literal;
		this.lexeme = lexeme;
    this.file = file;
		this.line = line;
	}

	String toString() {
		return type.toString() + " " + lexeme + " " + literal.toString();
	}
}
