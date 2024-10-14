using module .\Expr.psm1


class AstPrinter: ExprVisitor {
	[Object] print([Expr]$expr) {
		return $expr.accept($this)
	}

	[Object] visitTernaryExpr([Ternary]$expr) {
		return $this.parenthesize("?:", @($expr.cond, $expr.left, $expr.right))
	}

	[Object] visitBinaryExpr([Binary]$expr) {
		return $this.parenthesize($expr.operator.lexeme, @($expr.left, $expr.right))
	}

	[Object] visitGroupingExpr([Grouping]$expr) {
		return $this.parenthesize("group", @($expr.expression))
	}

	[Object] visitLiteralExpr([Literal]$expr) {
		if ($null -eq $expr.value) {
			return "nil"
		}
		return $expr.value
	}

	[Object] visitUnaryExpr([Unary]$expr) {
		return $this.parenthesize($expr.operator.lexeme, @($expr.right))
	}

	[Object] parenthesize([string]$name, [Expr[]]$exprs) {
		$sb = [System.Text.StringBuilder]::new()
		[void]$sb.Append("(")
		[void]$sb.Append($name)
		foreach ($expr in $exprs) {
			[void]$sb.Append(" ")
			if ($null -ne $expr) {
				[void]$sb.Append($expr.accept($this))
			}
			else {
				# null expressions means nothing, so we just wrap them in <#nothing#>
				[void]$sb.Append("<#nothing#>")
			}
		}
		[void]$sb.Append(")")
		return $sb.ToString()
	}
}

