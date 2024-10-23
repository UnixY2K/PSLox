using module .\Interpreter.psm1
using module ..\Lox\Stmt.psm1
using module ..\Lox\Expr.psm1
using module ..\Lox\Token.psm1
using module ..\Lox\Lox.psm1

using namespace System.Collections.Generic


enum FunctionType {
	NONE
	FUNCTION
}

class Resolver: StmtVisitor {
	[Interpreter] hidden $interpreter
	[Stack[Dictionary[string, bool]]] hidden $scopes = [Stack[Dictionary[string, bool]]]::new()
	[FunctionType] hidden $currentFunction = [FunctionType]::NONE

	Resolver([Interpreter] $interpreter) {
		$this.interpreter = $interpreter
	}

	[void] resolve([List[Stmt]] $statements) {
		foreach ($stmt in $statements) {
			$this.resolve($stmt)
		}
	}

	[void] hidden resolve([Stmt] $stmt) {
		$stmt.accept($this)
	}

	[void] hidden resolve([Expr] $expr) {
		$expr.accept($this)
	}

	[void] hidden resolveFunction([Function] $function, [FunctionType] $type) {
		[FunctionType] $enclosingFunction = $this.currentFunction
		$this.currentFunction = $type
		$this.beginScope()
		foreach ($param in $function.params) {
			$this.declareScope($param.lexeme)
			$this.defineScope($param.lexeme)
		}
		$this.resolve($function.body)
		$this.endScope()
		$this.currentFunction = $enclosingFunction
	}

	[void] hidden resolveLambda([Lambda] $lambda) {
		$this.beginScope()
		foreach ($param in $lambda.params) {
			$this.declareScope($param.lexeme)
			$this.defineScope($param.lexeme)
		}
		$this.resolve($lambda.body)
		$this.endScope()
	}

	[void] hidden beginScope() {
		$this.scopes.Push([Dictionary[string, bool]]::new())
	}

	[void] hidden endScope() {
		$this.scopes.Pop()
	}

	[void] hidden declareScope([string] $name) {
		if ($this.scopes.Count -eq 0) {
			return
		}

		if ($this.scopes.Peek().ContainsKey($name)) {
			[Lox]::error($name, "Variable with this name already declared in this scope.")
		}

		$scope = $this.scopes.Peek()
		$scope[$name] = $false
	}

	[void] hidden defineScope([string] $name) {
		if ($this.scopes.Count -eq 0) {
			return
		}
		$this.scopes.Peek()[$name] = $true
	}

	[void] hidden resolveLocal([Expr] $expr, [Token] $name) {
		for ($i = $this.scopes.Count - 1; $i -ge 0; $i--) {
			if ($this.scopes.ToArray()[$i].ContainsKey($name.lexeme)) {
				$this.interpreter.resolve($expr, $this.scopes.Count - 1 - $i)
				return
			}
		}
	}

	[void] visitBlockStmt([Block] $stmt) {
		$this.beginScope()
		$this.resolve($stmt.statements)
		$this.endScope()
	}

	[void] visitTerminalExprStmt([TerminalExpr] $stmt) {
		$this.resolve($stmt.expression)
	}

	[void] visitExpressionStmt([Expression] $stmt) {
		$this.resolve($stmt.expression)
	}

	[void] visitFunctionStmt([Function] $stmt) {
		$this.declareScope($stmt.name.lexeme)
		$this.defineScope($stmt.name.lexeme)
		$this.resolveFunction($stmt, [FunctionType]::FUNCTION)
	}

	[void] visitIfStmt([If] $stmt) {
		$this.resolve($stmt.condition)
		$this.resolve($stmt.thenBranch)
		if ($null -ne $stmt.elseBranch) {
			$this.resolve($stmt.elseBranch)
		}
	}

	[void] visitPrintStmt([Print] $stmt) {
		$this.resolve($stmt.expression)
	}

	[void] visitJumpStmt([Jump] $stmt) {
		if ($this.currentFunction -eq [FunctionType]::NONE) {
			switch ($stmt.keyword.type) {
				TOKEN_CONTINUE {
					[Lox]::error($stmt.keyword, "Cannot use 'continue' outside of a loop.")
				}
				TOKEN_BREAK {
					[Lox]::error($stmt.keyword, "Cannot use 'break' outside of control structure.")
				}
				TOKEN_RETURN {
					[Lox]::error($stmt.keyword, "Cannot 'return' from top-level code.")
				}
			}
		}
		# if there is a value we resolve it
		if ($null -ne $stmt.value) {
			$this.resolve($stmt.value)
		}
	}

	[void] visitVarStmt([Var] $stmt) {
		$this.declareScope($stmt.name)
		if ($null -ne $stmt.initializer) {
			$this.resolve($stmt.initializer)
		}
		$this.defineScope($stmt.name)
	}

	[void] visitWhileStmt([While] $stmt) {
		$this.resolve($stmt.condition)
		$this.resolve($stmt.body)
	}

	[void] visitTernaryExpr([Ternary] $expr) {
		$this.resolve($expr.cond)
		$this.resolve($expr.left)
		$this.resolve($expr.right)
	}

	[void] visitAssignExpr([Assign] $expr) {
		$this.resolve($expr.value)
		$this.resolveLocal($expr, $expr.name)
	}

	[void] visitBinaryExpr([Binary] $expr) {
		$this.resolve($expr.left)
		$this.resolve($expr.right)
	}

	[void] visitCallExpr([Call] $expr) {
		$this.resolve($expr.callee)
		foreach ($arg in $expr.arguments) {
			$this.resolve($arg)
		}
	}

	[void] visitGroupingExpr([Grouping] $expr) {
		$this.resolve($expr.expression)
	}

	[void] visitLiteralExpr([Literal] $expr) {
	}

	[void] visitLogicalExpr([Logical] $expr) {
		$this.resolve($expr.left)
		$this.resolve($expr.right)
	}

	[void] visitUnaryExpr([Unary] $expr) {
		$this.resolve($expr.right)
	}

	[void] visitVariableExpr([Variable] $expr) {
		if ($this.scopes.Count -ne 0) {
			$scope = $this.scopes.Peek()
			if ($scope.ContainsKey($expr.name.lexeme) -and $scope[$expr.name.lexeme] -eq $false) {
				[Lox]::error($expr.name, "Cannot read local variable in its own initializer.")
			}
		}
		$this.resolveLocal($expr, $expr.name)
	}

	[void] visitLambdaExpr([Lambda] $expr) {
		# the difference between functions is that lambdas don't have a name
		# so we don't need to declare and define the scope
		# but still we resolve the parameters and the body
		$this.resolveLambda($expr)
	}



}
