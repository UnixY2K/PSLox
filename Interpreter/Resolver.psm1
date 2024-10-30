using module .\Interpreter.psm1
using module ..\Lox\Stmt.psm1
using module ..\Lox\Expr.psm1
using module ..\Lox\Token.psm1
using module ..\Lox\Lox.psm1

using namespace System.Collections.Generic


enum FunctionType {
	NONE
	FUNCTION
	INITIALIZER
	METHOD
}

enum ClassType {
	NONE
	CLASS
	SUBCLASS
}

class Resolver: StmtVisitor {
	[Interpreter] hidden $interpreter
	[Stack[Dictionary[string, bool]]] hidden $scopes = [Stack[Dictionary[string, bool]]]::new()
	[FunctionType] hidden $currentFunction = [FunctionType]::NONE
	[ClassType] hidden $currentClass = [ClassType]::NONE

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
			$this.declareScope($param)
			$this.defineScope($param)
		}
		$this.resolve($function.body)
		$this.endScope()
		$this.currentFunction = $enclosingFunction
	}

	[void] hidden resolveLambda([Lambda] $lambda) {
		$this.beginScope()
		foreach ($param in $lambda.params) {
			$this.declareScope($param)
			$this.defineScope($param)
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

	[void] hidden declareScope([Token] $name) {
		if ($this.scopes.Count -eq 0) {
			return
		}

		if ($this.scopes.Peek().ContainsKey($name.lexeme)) {
			[Lox]::error($name, "Variable with this name already declared in this scope.")
		}

		$scope = $this.scopes.Peek()
		$scope[$name.lexeme] = $false
	}

	[void] hidden defineScope([Token] $name) {
		if ($this.scopes.Count -eq 0) {
			return
		}
		$this.scopes.Peek()[$name.lexeme] = $true
	}

	[void] hidden resolveLocal([Expr] $expr, [Token] $name) {
		$scopesA = $this.scopes.ToArray()
		# we need to get the array in powershell 
		# as is in LIFO order we do not iterate in reverse
		for ($i = 0; $i -lt $scopesA.Count; $i++) {
			if ($scopesA[$i].ContainsKey($name.lexeme)) {
				$this.interpreter.resolve($expr, $i)
				return
			}
		}
	}

	[void] visitBlockStmt([Block] $stmt) {
		$this.beginScope()
		$this.resolve($stmt.statements)
		$this.endScope()
	}

	[void] visitClassStmt([Class] $stmt) {
		[ClassType] $enclosingClass = $this.currentClass
		$this.currentClass = [ClassType]::CLASS

		$this.declareScope($stmt.name)
		$this.defineScope($stmt.name)

		if ($null -ne $stmt.superclass -and $stmt.name.lexeme -eq $stmt.superclass.name.lexeme) {
			[Lox]::error($stmt.superclass.name, "A class cannot inherit from itself.")
		}

		if ($null -ne $stmt.superclass) {
			$this.resolve($stmt.superclass)
		}

		if ($null -ne $stmt.superclass) {
			$this.currentClass = [ClassType]::SUBCLASS
			$this.beginScope()
			$this.scopes.Peek()["super"] = $true
		}

		$this.beginScope()
		$this.scopes.Peek()["this"] = $true

		foreach ($method in $stmt.methods) {
			$declaration = [FunctionType]::METHOD
			if ($method.name.lexeme -eq "init") {
				$declaration = [FunctionType]::INITIALIZER
			}
			$this.resolveFunction($method, $declaration)
		}

		$this.endScope()
		$this.currentClass = $enclosingClass

		if ($null -ne $stmt.superclass) {
			$this.endScope()
		}
	}

	[void] visitTerminalExprStmt([TerminalExpr] $stmt) {
		$this.resolve($stmt.expression)
	}

	[void] visitExpressionStmt([Expression] $stmt) {
		$this.resolve($stmt.expression)
	}

	[void] visitFunctionStmt([Function] $stmt) {
		$this.declareScope($stmt.name)
		$this.defineScope($stmt.name)
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
			if ($this.currentFunction -eq [FunctionType]::INITIALIZER) {
				[Lox]::error($stmt.keyword, "Cannot return a value from an initializer.")
			}
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

	[void] visitGetExpr([Get] $expr) {
		$this.resolve($expr.object)
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

	[void] visitSetExpr([Set] $expr) {
		$this.resolve($expr.value)
		$this.resolve($expr.object)
	}

	[void] visitSuperExpr([Super] $expr) {
		if ($this.currentClass -eq [ClassType]::NONE) {
			[Lox]::error($expr.keyword, "Cannot use 'super' outside of a class.")
		}
		elseif ($this.currentClass -ne [ClassType]::SUBCLASS) {
			[Lox]::error($expr.keyword, "Cannot use 'super' in a class with no superclass.")
		}

		$this.resolveLocal($expr, $expr.keyword)
	}

	[void] visitThizExpr([Thiz] $expr) {
		if ($this.currentClass -eq [ClassType]::NONE) {
			[Lox]::error($expr.keyword, "Cannot use 'this' outside of a class.")
			return
		}

		$this.resolveLocal($expr, $expr.keyword)
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
