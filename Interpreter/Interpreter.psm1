using module ../Lox/Lox.psm1
using module ../Lox/RuntimeError.psm1
using module ../Lox/Expr.psm1
using module ../Lox/Stmt.psm1
using module ../Lox/Token.psm1
using module ../Lox/TokenType.psm1
using module ../Lox/Environment.psm1
using module ./LoxCallable.psm1

using namespace System.Collections.Generic

class Interpreter: StmtVisitor {

	[Environment] hidden $globals = [Environment]::new()
	[Environment] hidden $environment = $globals

	Interpreter() {
		$this.environment = $this.globals
		$this.globals.define("clock", [NativeLoxCallable]::new(0, { [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }))
	}

	[void] interpret([List[Stmt]] $Statements) { 
		try {
			foreach ($statement in $statements) {
				$this.execute($statement)
			}
		}
		catch [RuntimeError] {
			[Lox]::runtimeError($_.Exception)
		}
	}

	[Object] visitTernaryExpr([Ternary]$expr) {
		[Object] $conditional = $this.evaluate($expr.cond)
		if ($this.isTruthy($conditional)) {
			$left =	($null -ne $expr.left) ? $this.evaluate($expr.left) : $conditional
			return $left 
		}
		return $this.evaluate($expr.right)
	}

	[Object] visitBinaryExpr([Binary]$expr) {
		[Object] $left = $this.evaluate($expr.left)
		[Object] $right = $this.evaluate($expr.right)

		return (& { switch ($expr.operator.type) {
					TOKEN_MINUS {
						$this.checkNumberOperands($expr.operator, $left, $right)
						return ([double]$left) - ([double]$right)
					}
					TOKEN_PLUS {
						if ($left -is ([double]) -and $right -is ([double])) {
							return [double]$left + [double]$right
						} 
						if ($left -is ([string]) -or $right -is ([string])) {
							return [string]$left + [string]$right
						}
						throw [RuntimeError]::new($expr.operator, "Both operands must be the same type or one string")
					}
					TOKEN_SLASH {
						$this.checkNumberOperands($expr.operator, $left, $right)
						return ([double]$left) / ([double]$right)
					}
					TOKEN_STAR {
						$this.checkNumberOperands($expr.operator, $left, $right)
						return ([double]$left) * ([double]$right)
					}
					TOKEN_GREATER {
						$this.checkNumberOperands($expr.operator, $left, $right)
						return ([double]$left) -gt ([double]$right)
					}
					TOKEN_GREATER_EQUAL {
						$this.checkNumberOperands($expr.operator, $left, $right)
						return ([double]$left) -ge ([double]$right)
					}
					TOKEN_LESS {
						$this.checkNumberOperands($expr.operator, $left, $right)
						return ([double]$left) -lt ([double]$right)
					}
					TOKEN_BANG_EQUAL {
						return !$this.isEqual($left, $right)
					}
					TOKEN_EQUAL_EQUAL {
						return $this.isEqual($left, $right)
					}
					TOKEN_COMMA {
						return $right
					}
					Default {
						throw [RuntimeError]::new($expr.operator, "operand not supported for binary expression")
					}
				} })
	}

	[Object] visitCallExpr([Call]$expr) {
		[Object] $callee = $this.evaluate($expr.callee)

		[List[Object]] $arguments = [List[Object]]::new()
		foreach ($argument in $expr.arguments) {
			$arguments.Add($this.evaluate($argument))
		}

		if ($callee -isnot [LoxCallable]) {
			throw [RuntimeError]::new($expr.paren, "Can only call functions and classes.")
		}
		[LoxCallable] $function = $callee -as [LoxCallable]
		if ($arguments.Count -ne $function.arity()) {
			throw [RuntimeError]::new($expr.paren, "Expected $($function.arity()) arguments but got $($arguments.Count).")
		}
		return $function.call($this, $arguments)
	}

	[Object] visitGroupingExpr([Grouping]$expr) {
		return $this.evaluate($expr.expression)
	}

	[Object] visitLiteralExpr([Literal]$expr) {
		return $expr.value
	}

	[Object] visitLogicalExpr([Logical]$expr) {
		[Object] $left = $this.evaluate($expr.left)

		if ($expr.operator.type -eq [TokenType]::TOKEN_OR) {
			if ($this.isTruthy($left)) { return $left }
		}
		else {
			if (!$this.isTruthy($left)) { return $left }
		}
		return $this.evaluate($expr.right)
	}

	[Object] visitUnaryExpr([Unary]$expr) {
		[Object] $right = $this.evaluate($expr.right)

		return (& { switch ($expr.operator.type) {
					TOKEN_BANG {
						return !$this.isTruthy($right)
					}
					TOKEN_MINUS {
						$this.checkNumberOperand($expr.operator, $right)
						return - ([double]$right)
					}
					Default {
						throw [RuntimeError]::new($expr.operator, "operand not supported for unary expression")
					}
				} })
	}

	[Object] visitVariableExpr([Variable]$expr) {
		return $this.environment.get($expr.name)
	}

	[boolean] hidden isTruthy([Object] $object) {
		if ($null -eq $object) { return $false }
		if ($object -is ([boolean])) { return [boolean]$object }
		return $true
	}

	[boolean] hidden isEqual([object] $a, [object] $b) {
		if ([double]::IsNaN($a) -and [double]::IsNaN($b)) {
			return $true
		}
		return $a -eq $b
	}

	[void] hidden checkNumberOperand([Token] $operator, [object] $operand) {
		if ($operand -is ([double])) { return }
		throw [RuntimeError]::new($operator, "Operand must be a number.")
	}

	[void] hidden checkNumberOperands([Token] $operator, [object] $left, [object]$right) {
		if (($left -is ([double])) -and ($right -is ([double]))) { return }
		throw [RuntimeError]::new($operator, "Operand must be a number.")
	}


	[Object] hidden evaluate([Expr] $expr) {
		return $expr.accept($this)
	}

	[void] hidden execute([Stmt] $stmt) {
		$stmt.accept($this)
	}

	[void] executeBlock([List[Stmt]] $statements, [Environment] $environment) {
		[Environment] $previous = $this.environment
		try {
			$this.environment = $environment
			foreach ($statement in $statements) {
				$this.execute($statement)
			}
		}
		finally {
			$this.environment = $previous
		}
	}

	[void] visitBlockStmt([Block] $stmt) {
		$this.executeBlock($stmt.statements, [Environment]::new($this.environment))
	}

	[void] visitTerminalExprStmt([TerminalExpr] $stmt) {
		if ($null -ne $stmt.expression) {
			[object] $value = $this.evaluate($stmt.expression)
			Write-Host $this.stringify($value)
		}
	}

	[void] visitExpressionStmt([Expression] $stmt) {
		$this.evaluate($stmt.expression)
	}

	[void] visitFunctionStmt([Function] $stmt) {
		[LoxFunction] $function = [LoxFunction]::new($stmt)
		$this.environment.define($stmt.name.lexeme, $function)
	}

	[void] visitIfStmt([If] $stmt) {
		if ($this.isTruthy($this.evaluate($stmt.condition))) {
			$this.execute($stmt.thenBranch)
		}
		elseif ($null -ne $stmt.elseBranch) {
			$this.execute($stmt.elseBranch)
		}
	}

	[void] visitPrintStmt([Print] $stmt) {
		[Object] $value = $this.evaluate($stmt.expression)
		Write-Host $this.stringify($value)
	}

	[void] visitVarStmt([Var] $stmt) {
		[Object] $value = [void]
		if ($null -ne $stmt.initializer) {
			$value = $this.evaluate($stmt.initializer)
		}
		$this.environment.define($stmt.name.lexeme, $value)
	}

	[void] visitWhileStmt([While] $stmt) {
		while ($this.isTruthy($this.evaluate($stmt.condition))) {
			$this.execute($stmt.body)
		}
	}

	[object] hidden visitAssignExpr([Assign] $expr) {
		[Object] $value = $this.evaluate($expr.value)
		$this.environment.assign($expr.name, $value)
		return $value
	}

	[string] hidden stringify([object] $object) {
		if ($null -eq $object) { return "nil" }	
		if ($object -is ([boolean])) {
			return $object.ToString().ToLowerInvariant()
		}
		return $object.toString()
	}
}
