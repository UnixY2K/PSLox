using module .\Token.psm1
using module .\TokenType.psm1
using module .\Expr.psm1
using module .\Stmt.psm1
using module .\Lox.psm1

using namespace System.Collections.Generic

class ParseError: System.Exception {
	ParseError() : base () {}
}

class Parser {
	[List[Token]] hidden $Tokens = [List[Token]]::new()
	[int] hidden $Current = 0

	Parser([List[Token]]$Tokens = @()) { $this.Init($Tokens) }

	[void] Init([List[Token]]$Tokens) {
		$this.Tokens = $Tokens
	}

	[List[Stmt]] parse() {
		try {
			[List[Stmt]] $statements = [List[Stmt]]::new()
			while (!$this.isAtEnd()) {
				$statements.add($this.declaration())
			}
			return $statements
		}
		catch [ParseError] {
			return $null
		}
	}

	[Expr] hidden expression() {
		return $this.comma()
	}

	[Stmt] hidden declaration() {
		try {
			if ($this.match(@([TokenType]::TOKEN_VAR))) { return $this.varDeclaration() }
			return $this.statement()
		}
		catch [ParseError] {
			$this.synchronize()
			return $null
		}
	}

	[Stmt] hidden statement() {
		if ($this.match(@([TokenType]::TOKEN_PRINT))) { return $this.printStatement() }
		if ($this.match(@([TokenType]::TOKEN_LEFT_BRACE))) { return [Block]::new($this.block()) }
	
		return $this.expressionStatement()
	}

	[Stmt] hidden printStatement() {
		[Expr] $value = $this.expression()
		$this.consume([TokenType]::TOKEN_SEMICOLON, "Expect ';' after value.")
		return [Print]::new($value)
	}

	[Stmt] hidden varDeclaration() {
		[Token] $name = $this.consume([TokenType]::TOKEN_IDENTIFIER, "Expect variable name.")
	
		[Expr] $initializer = $null
		if ($this.match(@([TokenType]::TOKEN_EQUAL))) {
			$initializer = $this.expression()
		}
	
		$this.consume([TokenType]::TOKEN_SEMICOLON, "Expect ';' after variable declaration.")
		return [Var]::new($name, $initializer)
	}

	[Stmt] hidden expressionStatement() {
		[Expr] $expr = $this.expression()
		if ($this.match(@([TokenType]::TOKEN_SEMICOLON))) {
			return [Expression]::new($expr)
		}
		return [TerminalExpr]::new($expr)
	}

	[List[Stmt]] hidden block() {
		[List[Stmt]] $statements = [List[Stmt]]::new()
	
		while (!$this.check([TokenType]::TOKEN_RIGHT_BRACE) -and !$this.isAtEnd()) {
			$statements.add($this.declaration())
		}
	
		$this.consume([TokenType]::TOKEN_RIGHT_BRACE, "Expect '}' after block.")
		# add a terminal statement to the block if the last statement is not a terminal statement
		if ($statements[-1] -isnot [TerminalExpr]) {
			$statements.add([TerminalExpr]::new($null))
		}
		return $statements
	}

	[Expr] hidden comma() {
		$expr = $this.assingment()
		
		while ($this.match(@([TokenType]::TOKEN_COMMA))) {
			[Token] $operator = $this.previous()
			[Expr] $right = $this.expression()
			$expr = [Binary]::new($expr, $operator, $right)
		}
		
		return $expr
	}

	[Expr] hidden assingment() {
		[Expr] $expr = $this.ternary()

		if ($this.match(@([TokenType]::TOKEN_EQUAL))) {
			[Token] $equals = $this.previous()
			[Expr] $value = $this.assingment()

			if ($expr -is [Variable]) {
				[Token] $name = $expr.name
				return [Assign]::new($name, $value)
			}
			$this.error($equals, "Invalid assignment target.")
		}

		return $expr
	}

	[Expr] hidden ternary() {

		$expr = $this.equality()
		
		while ($this.match(@([TokenType]::TOKEN_QUESTION))) {
			#[Token] $operator = $this.previous()
			[Expr]$left = $null
			# '(Expr)?:(Expr) check aka. Elvis operator'
			if ($this.check([TokenType]::TOKEN_COLON)) {
				$this.advance()
			}
			else {
				$left = $this.expression()
				$this.consume([TokenType]::TOKEN_COLON, "Expect ':' after expression.")
			}

			[Expr]$right = $this.expression()

			$expr = [Ternary]::new($expr, $left, $right)
		}
		
		return $expr
	}

	[Expr] hidden equality() {
		[Expr] $expr = $this.comparison()

		while ($this.match(@([TokenType]::TOKEN_BANG_EQUAL, [TokenType]::TOKEN_EQUAL_EQUAL))) {
			[Token] $operator = $this.previous()
			[Expr] $right = $this.comparison()
			$expr = [Binary]::new($expr, $operator, $right)
		}

		return $expr
	}

	[Expr] hidden comparison() {
		[Expr] $expr = $this.term()
	
		while ($this.match(@([TokenType]::TOKEN_GREATER, [TokenType]::TOKEN_GREATER_EQUAL, [TokenType]::TOKEN_LESS, [TokenType]::TOKEN_LESS_EQUAL))) {
			[Token] $operator = $this.previous()
			[Expr] $right = $this.term()
			$expr = [Binary]::new($expr, $operator, $right)
		}
	
		return $expr
	}

	[Expr] hidden term() {
		[Expr] $expr = $this.factor()
	
		while ($this.match(@([TokenType]::TOKEN_MINUS, [TokenType]::TOKEN_PLUS))) {
			[Token] $operator = $this.previous()
			[Expr] $right = $this.factor()
			$expr = [Binary]::new($expr, $operator, $right)
		}
	
		return $expr
	}

	[Expr] hidden factor() {
		[Expr] $expr = $this.unary()
	
		while ($this.match(@([TokenType]::TOKEN_SLASH, [TokenType]::TOKEN_STAR))) {
			[Token] $operator = $this.previous()
			[Expr] $right = $this.unary()
			$expr = [Binary]::new($expr, $operator, $right)
		}
	
		return $expr
	}

	[Expr] hidden unary() {
		if ($this.match(@([TokenType]::TOKEN_BANG, [TokenType]::TOKEN_MINUS))) {
			[Token] $operator = $this.previous()
			[Expr] $right = $this.unary()
			return [Unary]::new($operator, $right)
		}
		return $this.primary()
	}

	[Expr] hidden primary() {
		if ($this.match(@([TokenType]::TOKEN_FALSE))) { return [Literal]::new($false) }
		if ($this.match(@([TokenType]::TOKEN_TRUE))) { return [Literal]::new($true) }
		if ($this.match(@([TokenType]::TOKEN_NIL))) { return [Literal]::new($null) }
	
		if ($this.match(@([TokenType]::TOKEN_NUMBER, [TokenType]::TOKEN_STRING))) {
			return [Literal]::new($this.previous().literal)
		}

		if ($this.match(@([TokenType]::TOKEN_IDENTIFIER))) {
			return [Variable]::new($this.previous())
		}
	
		if ($this.match(@([TokenType]::TOKEN_LEFT_PAREN))) {
			[Expr] $expr = $this.expression()
			$this.consume([TokenType]::TOKEN_RIGHT_PAREN, "Expect ')' after expression.")
			return [Grouping]::new($expr)
		}
		throw $this.error($this.peek(), "Expect expression.")
	}
	

	[bool] hidden match(
		[List[TokenType]] $types
	) {
		foreach ($type in $types) {
			if ($this.check($type)) {
				$this.advance()
				return $true
			}
		}
		return $false
	}

	[boolean] hidden check([TokenType] $type) {
		if ($this.isAtEnd()) { return $false }
		return $this.peek().type -eq $type
	}

	[Token] hidden advance() {
		if (!$this.isAtEnd()) { $this.Current++ }
		return $this.previous()
	}

	[boolean] hidden isAtEnd() {
		return $this.peek().type -eq [TokenType]::TOKEN_EOF
	}
	
	[Token] hidden peek() {
		return $this.Tokens[$this.Current]
	}
	
	[Token] hidden previous() {
		return $this.Tokens[$this.Current - 1]
	}

	[Token] hidden consume([TokenType] $type, [String] $message) {
		if ($this.check($type)) { return $this.advance() }
	
		throw $this.error($this.peek(), $message)
	}

	[ParseError] hidden error([Token] $token, [string] $message) {
		[Lox]::error($token, $message)
		return [ParseError]::new()
	}

	[void] hidden synchronize() {
		$this.advance()
	
		while (!$this.isAtEnd()) {
			if ($this.previous().type -eq [TokenType]::TOKEN_SEMICOLON) { return }
	
			if ($_ -in
				@(
					[TokenType]::TOKEN_CLASS,
					[TokenType]::TOKEN_FUN,
					[TokenType]::TOKEN_VAR,
					[TokenType]::TOKEN_FOR,
					[TokenType]::TOKEN_IF,
					[TokenType]::TOKEN_WHILE,
					[TokenType]::TOKEN_PRINT,
					[TokenType]::TOKEN_RETURN) 
			) {
				return
			}
			$this.advance()
		}
	}

}
