import './tokens.dart';
import './expr.dart';

abstract class Stmt {
    accept(StmtVisitor visitor);
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


class PrintStmt extends Stmt {
	Expr expression;

	PrintStmt(Expr expression) {
		this.expression = expression;
	}

	accept(StmtVisitor visitor) {
		return visitor.visitPrintStmt(this);
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


abstract class StmtVisitor {

	visitExpressionStmt(ExpressionStmt expr) {
		return expr.accept(this);
	}

	visitPrintStmt(PrintStmt expr) {
		return expr.accept(this);
	}

	visitVarStmt(VarStmt expr) {
		return expr.accept(this);
	}

}
