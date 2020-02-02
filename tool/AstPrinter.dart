import '../src/expr.dart';

class AstPrinter implements ExprVisitor {
  
	String print(Expr expr) {
		return expr.accept(this);
	}
  
	String parenthesize(String name, List<Expr> list) {
		StringBuffer buffer = new StringBuffer();

		buffer.write('($name');
		list.forEach((Expr expr) => buffer.write(' ' + expr.accept(this)));

		buffer.write(')');

		return buffer.toString();
	}

	@override
	String visitBinaryExpr(BinaryExpr expr) {
		return this.parenthesize(expr.op.lexeme, [expr.left, expr.right]);
	}

	@override
	String visitGroupingExpr(GroupingExpr expr) {
		return this.parenthesize('group', [expr.expr]);
	}

	@override
	String visitLiteralExpr(LiteralExpr expr) {
		return expr.value == null ? 'nil' : expr.value.toString();
	}

	@override
	String visitUnaryExpr(UnaryExpr expr) {
		return this.parenthesize(expr.op.lexeme, [expr.right]);
	}

  @override
  visitVariableExpr(VariableExpr expr) {
    // TODO: implement visitVariableExpr
    return null;
  }
}