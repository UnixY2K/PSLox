using module .\Token.psm1
using module .\Expr.psm1
using namespace System.Collections.Generic


class StmtVisitor : ExprVisitor {
	visitBlockStmt([Block]$Block) {}
	visitClassStmt([Class]$Class) {}
	visitTerminalExprStmt([TerminalExpr]$TerminalExpr) {}
	visitExpressionStmt([Expression]$Expression) {}
	visitFunctionStmt([Function]$Function) {}
	visitIfStmt([If]$If) {}
	visitPrintStmt([Print]$Print) {}
	visitJumpStmt([Jump]$Jump) {}
	visitVarStmt([Var]$Var) {}
	visitWhileStmt([While]$While) {}
}

class Stmt {
	[Object] accept([StmtVisitor]$Visitor) { return $null }
}

class Block : Stmt {
	[List[Stmt]] $statements

	Block([List[Stmt]] $statements) {
		$this.statements = $statements
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitBlockStmt($this)
	}
}

class Class : Stmt {
	[Token] $name
	[List[Function]] $methods

	Class([Token] $name, [List[Function]] $methods) {
		$this.name = $name
		$this.methods = $methods
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitClassStmt($this)
	}
}

class TerminalExpr : Stmt {
	[Expr] $expression

	TerminalExpr([Expr] $expression) {
		$this.expression = $expression
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitTerminalExprStmt($this)
	}
}

class Expression : Stmt {
	[Expr] $expression

	Expression([Expr] $expression) {
		$this.expression = $expression
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitExpressionStmt($this)
	}
}

class Function : Stmt {
	[Token] $name
	[List[Token]] $params
	[List[Stmt]] $body

	Function([Token] $name, [List[Token]] $params, [List[Stmt]] $body) {
		$this.name = $name
		$this.params = $params
		$this.body = $body
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitFunctionStmt($this)
	}
}

class If : Stmt {
	[Expr] $condition
	[Stmt] $thenBranch
	[Stmt] $elseBranch

	If([Expr] $condition, [Stmt] $thenBranch, [Stmt] $elseBranch) {
		$this.condition = $condition
		$this.thenBranch = $thenBranch
		$this.elseBranch = $elseBranch
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitIfStmt($this)
	}
}

class Print : Stmt {
	[Expr] $expression

	Print([Expr] $expression) {
		$this.expression = $expression
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitPrintStmt($this)
	}
}

class Jump : Stmt {
	[Token] $keyword
	[Expr] $value

	Jump([Token] $keyword, [Expr] $value) {
		$this.keyword = $keyword
		$this.value = $value
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitJumpStmt($this)
	}
}

class Var : Stmt {
	[Token] $name
	[Expr] $initializer

	Var([Token] $name, [Expr] $initializer) {
		$this.name = $name
		$this.initializer = $initializer
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitVarStmt($this)
	}
}

class While : Stmt {
	[Expr] $condition
	[Stmt] $body

	While([Expr] $condition, [Stmt] $body) {
		$this.condition = $condition
		$this.body = $body
	}
	[Object] accept([StmtVisitor]$Visitor) {
		return $Visitor.visitWhileStmt($this)
	}
}


