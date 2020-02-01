import './tokens.dart';

abstract class Expr {
    accept(ExprVisitor visitor);
}

class BinaryExpr extends Expr {
	Expr left;
	Token op;
	Expr right;

	BinaryExpr(Expr left, Token op, Expr right) {
		this.left = left;
		this.op = op;
		this.right = right;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitBinaryExpr(this);
	}
}


class GroupingExpr extends Expr {
	Expr expr;

	GroupingExpr(Expr expr) {
		this.expr = expr;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitGroupingExpr(this);
	}
}


class LiteralExpr extends Expr {
	Object value;

	LiteralExpr(Object value) {
		this.value = value;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitLiteralExpr(this);
	}
}


class UnaryExpr extends Expr {
	Token op;
	Expr right;

	UnaryExpr(Token op, Expr right) {
		this.op = op;
		this.right = right;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitUnaryExpr(this);
	}
}


abstract class ExprVisitor {

	visitBinaryExpr(BinaryExpr expr) {
		return expr.accept(this);
	}

	visitGroupingExpr(GroupingExpr expr) {
		return expr.accept(this);
	}

	visitLiteralExpr(LiteralExpr expr) {
		return expr.accept(this);
	}

	visitUnaryExpr(UnaryExpr expr) {
		return expr.accept(this);
	}

}
