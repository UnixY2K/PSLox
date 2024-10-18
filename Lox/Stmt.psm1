using module .\Expr.psm1
using module .\Token.psm1
using namespace System.Collections.Generic


class StmtVisitor : ExprVisitor {
	visitBlockStmt([Block]$Block) {}
	visitExpressionStmt([Expression]$Expression) {}
	visitPrintStmt([Print]$Print) {}
	visitVarStmt([Var]$Var) {}
}

class Stmt {
	[Object] accept([StmtVisitor]$Visitor) { return $null }
}

class Block : Stmt {
	[List[Stmt]] hidden $statements

	Block([List[Stmt]] $statements) {
		$this.statements = $statements
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitBlockStmt($this)
	}
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


