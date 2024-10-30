using module .\Token.psm1
using namespace System.Collections.Generic


class ExprVisitor {
	visitTernaryExpr([Ternary]$Ternary) {}
	visitAssignExpr([Assign]$Assign) {}
	visitBinaryExpr([Binary]$Binary) {}
	visitCallExpr([Call]$Call) {}
	visitGetExpr([Get]$Get) {}
	visitGroupingExpr([Grouping]$Grouping) {}
	visitLiteralExpr([Literal]$Literal) {}
	visitLogicalExpr([Logical]$Logical) {}
	visitSetExpr([Set]$Set) {}
	visitSuperExpr([Super]$Super) {}
	visitThizExpr([Thiz]$Thiz) {}
	visitUnaryExpr([Unary]$Unary) {}
	visitVariableExpr([Variable]$Variable) {}
	visitLambdaExpr([Lambda]$Lambda) {}
}

class Expr {
	[Object] accept([ExprVisitor]$Visitor) { return $null }
}

class Ternary : Expr {
	[Expr] $cond
	[Expr] $left
	[Expr] $right

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
	[Token] $name
	[Expr] $value

	Assign([Token] $name, [Expr] $value) {
		$this.name = $name
		$this.value = $value
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitAssignExpr($this)
	}
}

class Binary : Expr {
	[Expr] $left
	[Token] $operator
	[Expr] $right

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
	[Expr] $callee
	[Token] $paren
	[List[Expr]] $arguments

	Call([Expr] $callee, [Token] $paren, [List[Expr]] $arguments) {
		$this.callee = $callee
		$this.paren = $paren
		$this.arguments = $arguments
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitCallExpr($this)
	}
}

class Get : Expr {
	[Expr] $object
	[Token] $name

	Get([Expr] $object, [Token] $name) {
		$this.object = $object
		$this.name = $name
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitGetExpr($this)
	}
}

class Grouping : Expr {
	[Expr] $expression

	Grouping([Expr] $expression) {
		$this.expression = $expression
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitGroupingExpr($this)
	}
}

class Literal : Expr {
	[Object] $value

	Literal([Object] $value) {
		$this.value = $value
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitLiteralExpr($this)
	}
}

class Logical : Expr {
	[Expr] $left
	[Token] $operator
	[Expr] $right

	Logical([Expr] $left, [Token] $operator, [Expr] $right) {
		$this.left = $left
		$this.operator = $operator
		$this.right = $right
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitLogicalExpr($this)
	}
}

class Set : Expr {
	[Expr] $object
	[Token] $name
	[Expr] $value

	Set([Expr] $object, [Token] $name, [Expr] $value) {
		$this.object = $object
		$this.name = $name
		$this.value = $value
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitSetExpr($this)
	}
}

class Super : Expr {
	[Token] $keyword
	[Token] $method

	Super([Token] $keyword, [Token] $method) {
		$this.keyword = $keyword
		$this.method = $method
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitSuperExpr($this)
	}
}

class Thiz : Expr {
	[Token] $keyword

	Thiz([Token] $keyword) {
		$this.keyword = $keyword
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitThizExpr($this)
	}
}

class Unary : Expr {
	[Token] $operator
	[Expr] $right

	Unary([Token] $operator, [Expr] $right) {
		$this.operator = $operator
		$this.right = $right
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitUnaryExpr($this)
	}
}

class Variable : Expr {
	[Token] $name

	Variable([Token] $name) {
		$this.name = $name
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitVariableExpr($this)
	}
}

class Lambda : Expr {
	[List[Token]] $params
	[List[Stmt]] $body

	Lambda([List[Token]] $params, [List[Stmt]] $body) {
		$this.params = $params
		$this.body = $body
	}
	[Object] accept([ExprVisitor]$Visitor) {
		return $Visitor.visitLambdaExpr($this)
	}
}


