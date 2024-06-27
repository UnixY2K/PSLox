using module .\Token.psm1


class ExprVisitor {
	visitBinaryExpr([Binary]$Binary) {}
	visitGroupingExpr([Grouping]$Grouping) {}
	visitLiteralExpr([Literal]$Literal) {}
	visitUnaryExpr([Unary]$Unary) {}
}

class Expr {
	[Object] accept([ExprVisitor]$Visitor) { return $null }
}

class Binary : Expr {
	[Expr] hidden $left
	[Token] hidden $operator
	[Expr] hidden $right

	Binary([Expr] $left, [Token] $operator, [Expr] $right) {
		$this.left = $left
		$this.operator = $operator
		$this.right = $right
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitBinaryExpr($this)
	}
}

class Grouping : Expr {
	[Expr] hidden $expression

	Grouping([Expr] $expression) {
		$this.expression = $expression
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitGroupingExpr($this)
	}
}

class Literal : Expr {
	[Object] hidden $value

	Literal([Object] $value) {
		$this.value = $value
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitLiteralExpr($this)
	}
}

class Unary : Expr {
	[Token] hidden $operator
	[Expr] hidden $right

	Unary([Token] $operator, [Expr] $right) {
		$this.operator = $operator
		$this.right = $right
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitUnaryExpr($this)
	}
}


