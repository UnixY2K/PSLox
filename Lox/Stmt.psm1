using module .\Expr.psm1


class StmtVisitor : ExprVisitor {
	visitExpressionExpr([Expression]$Expression) {}
	visitPrintExpr([Print]$Print) {}
}

class Stmt {
	[Object] accept([ExprVisitor]$Visitor) { return $null }
}

class Expression : Stmt {
	[Expr] hidden $expression

	Expression([Expr] $expression) {
		$this.expression = $expression
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitExpressionExpr($this)
	}
}

class Print : Stmt {
	[Expr] hidden $expression

	Print([Expr] $expression) {
		$this.expression = $expression
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitPrintExpr($this)
	}
}


