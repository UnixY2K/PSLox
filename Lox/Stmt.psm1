using module .\Expr.psm1
using module .\Token.psm1


class StmtVisitor : ExprVisitor {
	visitExpressionStmt([Expression]$Expression) {}
	visitPrintStmt([Print]$Print) {}
	visitVarStmt([Var]$Var) {}
}

class Stmt {
	[Object] accept([StmtVisitor]$Visitor) { return $null }
}

class Expression : Stmt {
	[Expr] hidden $expression

	Expression([Expr] $expression) {
		$this.expression = $expression
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitExpressionStmt($this)
	}
}

class Print : Stmt {
	[Expr] hidden $expression

	Print([Expr] $expression) {
		$this.expression = $expression
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitPrintStmt($this)
	}
}

class Var : Stmt {
	[Token] hidden $name
	[Expr] hidden $initializer

	Var([Token] $name, [Expr] $initializer) {
		$this.name = $name
		$this.initializer = $initializer
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitVarStmt($this)
	}
}


