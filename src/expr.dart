import './tokens.dart';

abstract class Expr {
    accept(ExprVisitor visitor);
}

class AssignExpr extends Expr {
	Token name;
	Expr value;

	AssignExpr(Token name, Expr value) {
		this.name = name;
		this.value = value;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitAssignExpr(this);
	}
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


class CallExpr extends Expr {
	Expr callee;
	Token paren;
	List<Expr> arguments;

	CallExpr(Expr callee, Token paren, List<Expr> arguments) {
		this.callee = callee;
		this.paren = paren;
		this.arguments = arguments;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitCallExpr(this);
	}
}


class GetExpr extends Expr {
	Expr object;
	Token name;

	GetExpr(Expr object, Token name) {
		this.object = object;
		this.name = name;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitGetExpr(this);
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


class LogicalExpr extends Expr {
	Expr left;
	Token opt;
	Expr right;

	LogicalExpr(Expr left, Token opt, Expr right) {
		this.left = left;
		this.opt = opt;
		this.right = right;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitLogicalExpr(this);
	}
}


class SetExpr extends Expr {
	Expr object;
	Token name;
	Expr value;

	SetExpr(Expr object, Token name, Expr value) {
		this.object = object;
		this.name = name;
		this.value = value;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitSetExpr(this);
	}
}


class SuperExpr extends Expr {
	Token keyword;
	Token method;

	SuperExpr(Token keyword, Token method) {
		this.keyword = keyword;
		this.method = method;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitSuperExpr(this);
	}
}


class ThisExpr extends Expr {
	Token keyword;

	ThisExpr(Token keyword) {
		this.keyword = keyword;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitThisExpr(this);
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


class VariableExpr extends Expr {
	Token name;

	VariableExpr(Token name) {
		this.name = name;
	}

	accept(ExprVisitor visitor) {
		return visitor.visitVariableExpr(this);
	}
}


abstract class ExprVisitor {

	visitAssignExpr(AssignExpr expr) {
		return expr.accept(this);
	}

	visitBinaryExpr(BinaryExpr expr) {
		return expr.accept(this);
	}

	visitCallExpr(CallExpr expr) {
		return expr.accept(this);
	}

	visitGetExpr(GetExpr expr) {
		return expr.accept(this);
	}

	visitGroupingExpr(GroupingExpr expr) {
		return expr.accept(this);
	}

	visitLiteralExpr(LiteralExpr expr) {
		return expr.accept(this);
	}

	visitLogicalExpr(LogicalExpr expr) {
		return expr.accept(this);
	}

	visitSetExpr(SetExpr expr) {
		return expr.accept(this);
	}

	visitSuperExpr(SuperExpr expr) {
		return expr.accept(this);
	}

	visitThisExpr(ThisExpr expr) {
		return expr.accept(this);
	}

	visitUnaryExpr(UnaryExpr expr) {
		return expr.accept(this);
	}

	visitVariableExpr(VariableExpr expr) {
		return expr.accept(this);
	}

}
