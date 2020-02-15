import 'tokens.dart';
import 'expr.dart';

abstract class Stmt {
    accept(StmtVisitor visitor);
}

class BlockStmt extends Stmt {
	List<Stmt> statements;

	BlockStmt(List<Stmt> statements) {
		this.statements = statements;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitBlockStmt(this);
	}
}


class ClassStmt extends Stmt {
	Token name;
	VariableExpr superclass;
	List<FunctionStmt> methods;

	ClassStmt(Token name, VariableExpr superclass, List<FunctionStmt> methods) {
		this.name = name;
		this.superclass = superclass;
		this.methods = methods;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitClassStmt(this);
	}
}


class ExpressionStmt extends Stmt {
	Expr expression;

	ExpressionStmt(Expr expression) {
		this.expression = expression;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitExpressionStmt(this);
	}
}


class FunctionStmt extends Stmt {
	Token name;
	List<Token> params;
	List<Stmt> body;
  bool isStatic = false;

	FunctionStmt(Token name, List<Token> params, List<Stmt> body, bool _static): isStatic = _static {
		this.name = name;
		this.params = params;
		this.body = body;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitFunctionStmt(this);
	}
}


class IfStmt extends Stmt {
	Expr condition;
	Stmt thenStmt;
	Stmt elseStmt;

	IfStmt(Expr condition, Stmt thenStmt, Stmt elseStmt) {
		this.condition = condition;
		this.thenStmt = thenStmt;
		this.elseStmt = elseStmt;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitIfStmt(this);
	}
}


class PrintStmt extends Stmt {
	Expr expression;

	PrintStmt(Expr expression) {
		this.expression = expression;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitPrintStmt(this);
	}
}


class ReturnStmt extends Stmt {
	Token keyword;
	Expr value;

	ReturnStmt(Token keyword, Expr value) {
		this.keyword = keyword;
		this.value = value;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitReturnStmt(this);
	}
}


class VarStmt extends Stmt {
	Token name;
	Expr initializer;

	VarStmt(Token name, Expr initializer) {
		this.name = name;
		this.initializer = initializer;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitVarStmt(this);
	}
}


class WhileStmt extends Stmt {
	Expr condition;
	Stmt body;

	WhileStmt(Expr condition, Stmt body) {
		this.condition = condition;
		this.body = body;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitWhileStmt(this);
	}
}


class BreakStmt extends Stmt {
	Token keyword;

	BreakStmt(Token keyword) {
		this.keyword = keyword;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitBreakStmt(this);
	}
}


class ImportStmt extends Stmt {
	Token keyword;
	LiteralExpr target;

	ImportStmt(Token keyword, LiteralExpr target) {
		this.keyword = keyword;
		this.target = target;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitImportStmt(this);
	}
}


class ThrowStmt extends Stmt {
	Token keyword;
	Expr message;

	ThrowStmt(Token keyword, Expr message) {
		this.keyword = keyword;
		this.message = message;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitThrowStmt(this);
	}
}


abstract class StmtVisitor {

	visitBlockStmt(BlockStmt expr) {
		return expr.accept(this);
	}

	visitClassStmt(ClassStmt expr) {
		return expr.accept(this);
	}

	visitExpressionStmt(ExpressionStmt expr) {
		return expr.accept(this);
	}

	visitFunctionStmt(FunctionStmt expr) {
		return expr.accept(this);
	}

	visitIfStmt(IfStmt expr) {
		return expr.accept(this);
	}

	visitPrintStmt(PrintStmt expr) {
		return expr.accept(this);
	}

	visitReturnStmt(ReturnStmt expr) {
		return expr.accept(this);
	}

	visitVarStmt(VarStmt expr) {
		return expr.accept(this);
	}

	visitWhileStmt(WhileStmt expr) {
		return expr.accept(this);
	}

	visitBreakStmt(BreakStmt expr) {
		return expr.accept(this);
	}

	visitImportStmt(ImportStmt expr) {
		return expr.accept(this);
	}

	visitThrowStmt(ThrowStmt expr) {
		return expr.accept(this);
	}

}
