using module .\Token.psm1
using namespace System.Collections.Generic


class ExprVisitor {
	visitTernaryExpr([Ternary]$Ternary) {}
	visitAssignExpr([Assign]$Assign) {}
	visitBinaryExpr([Binary]$Binary) {}
	visitCallExpr([Call]$Call) {}
	visitGroupingExpr([Grouping]$Grouping) {}
	visitLiteralExpr([Literal]$Literal) {}
	visitLogicalExpr([Logical]$Logical) {}
	visitUnaryExpr([Unary]$Unary) {}
	visitVariableExpr([Variable]$Variable) {}
	visitLambdaExpr([Lambda]$Lambda) {}
}

class Expr {
	[Object] accept([ExprVisitor]$Visitor) { return $null }
}

class Ternary : Expr {
	[Expr] hidden $cond
	[Expr] hidden $left
	[Expr] hidden $right

	Ternary([Expr] $cond, [Expr] $left, [Expr] $right) {
		$this.cond = $cond
		$this.left = $left
		$this.right = $right
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitTernaryExpr($this)
	}
}

class Assign : Expr {
	[Token] hidden $name
	[Expr] hidden $value

	Assign([Token] $name, [Expr] $value) {
		$this.name = $name
		$this.value = $value
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitAssignExpr($this)
	}
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

class Call : Expr {
	[Expr] hidden $callee
	[Token] hidden $paren
	[List[Expr]] hidden $arguments

	Call([Expr] $callee, [Token] $paren, [List[Expr]] $arguments) {
		$this.callee = $callee
		$this.paren = $paren
		$this.arguments = $arguments
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitCallExpr($this)
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

class Logical : Expr {
	[Expr] hidden $left
	[Token] hidden $operator
	[Expr] hidden $right

	Logical([Expr] $left, [Token] $operator, [Expr] $right) {
		$this.left = $left
		$this.operator = $operator
		$this.right = $right
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitLogicalExpr($this)
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

class Variable : Expr {
	[Token] hidden $name

	Variable([Token] $name) {
		$this.name = $name
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitVariableExpr($this)
	}
}

class Lambda : Expr {
	[List[Token]] hidden $params
	[List[Stmt]] hidden $body

	Lambda([List[Token]] $params, [List[Stmt]] $body) {
		$this.params = $params
		$this.body = $body
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitLambdaExpr($this)
	}
}


