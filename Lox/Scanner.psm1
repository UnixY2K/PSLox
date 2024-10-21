using module .\Token.psm1
using module .\TokenType.psm1
using module .\Lox.psm1

using namespace System.Collections.Generic

class Scanner {

	[string] hidden $Source = ""
	[List[Token]] hidden $Tokens = [List[Token]]::new()
	[int] hidden $Start = 0
	[int] hidden $Current = 0
	[int] hidden $Line = 1

	Scanner() { $this.Init(@{}) }
	Scanner([hashtable]$Properties) { $this.Init($Properties) }
	Scanner([string] $Source) {
		$this.Init(@{
				Source = $Source
			})
	}

	[void] Init([hashtable]$Properties) {
		foreach ($Property in $Properties.Keys) {
			$this.$Property = $Properties.$Property
		}
	}

	[bool] isAtEnd() {
		return $this.Current -ge $this.Source.Length
	}



	
	[List[Token]] scanTokens() {
		while (!$this.isAtEnd()) {
			$this.Start = $this.Current
			$this.scanToken()
		}
		[void]$this.Tokens.Add([Token]::new([TokenType]::TOKEN_EOF, "", $null, $this.Line))
		return $this.Tokens
	}

	[void] hidden scanToken() {
		[char] $c = $this.advance()
		switch ($c) {
			'(' { $this.addToken([TokenType]::TOKEN_LEFT_PAREN) }
			')' { $this.addToken([TokenType]::TOKEN_RIGHT_PAREN) }
			'{' { $this.addToken([TokenType]::TOKEN_LEFT_BRACE) }
			'}' { $this.addToken([TokenType]::TOKEN_RIGHT_BRACE) }
			',' { $this.addToken([TokenType]::TOKEN_COMMA) }
			'.' { $this.addToken([TokenType]::TOKEN_DOT) }
			'-' { $this.addToken([TokenType]::TOKEN_MINUS) }
			'+' { $this.addToken([TokenType]::TOKEN_PLUS) }
			';' { $this.addToken([TokenType]::TOKEN_SEMICOLON) }
			'*' { $this.addToken([TokenType]::TOKEN_STAR) } 
			'!' { $this.addToken($(if ($this.match('=')) { [TokenType]::TOKEN_BANG_EQUAL }		else { [TokenType]::TOKEN_BANG })) }
			'=' { $this.addToken($(if ($this.match('=')) { [TokenType]::TOKEN_EQUAL_EQUAL }		else { [TokenType]::TOKEN_EQUAL })) }
			'<' { $this.addToken($(if ($this.match('=')) { [TokenType]::TOKEN_LESS_EQUAL }		else { [TokenType]::TOKEN_LESS })) }
			'>' { $this.addToken($(if ($this.match('=')) { [TokenType]::TOKEN_GREATER_EQUAL }	else { [TokenType]::TOKEN_GREATER })) }
			'/' {
				if ($this.match('/')) {
					while ($this.peek() -ne "`n" -and !$this.isAtEnd()) {
						$this.advance()
					}
				}
				elseif ($this.match('*')) {
					while (!($this.peek() -eq '*' -and $this.peekNext() -eq '/') -and !$this.isAtEnd()) {
						if ($this.peek() -eq "`n") { $this.Line += 1 }
						$this.advance()
					}
					if ($this.isAtEnd()) {
						[Lox]::error($this.Line, "Unterminated block comment.")
					}
					$this.advance()
					$this.advance()
				}
				else {
					$this.addToken([TokenType]::TOKEN_SLASH)
				}
			}
			'?' { $this.addToken([TokenType]::TOKEN_QUESTION) }
			':' { $this.addToken([TokenType]::TOKEN_COLON) }
			{ $_ -in @(" ", "`r", "`t") } {}
			"`n" { $this.Line += 1 }
			'"' { $this.string() }
			{ [Scanner]::isDigit($_) } { $this.number() }
			{ [Scanner]::isAlpha($_) } { $this.identifier() }
			Default {
				[Lox]::error($this.Line, "Unexpected character.")
			}
		}
	}

	[char] hidden advance() {
		$this.Current += 1
		return $this.Source[$this.Current - 1]
	}

	[void] hidden addToken([TokenType] $type) {
		$this.addToken($type, $null)
	}
	[void] hidden addToken([TokenType] $type, [object] $literal = $null) {
		[string] $text = $this.Source.Substring($this.Start, $this.Current - $this.Start)
		[Token] $token = [Token]::new($type, $text, $literal, $this.Line)
		[void]$this.Tokens.Add($token)
	}
	
	[bool] hidden match([char] $expected) {
		if ($this.isAtEnd()) { return $false }
		if ($this.Source[$this.Current] -ne $expected) { return $false }
		$this.Current += 1
		return $true
	}

	[void] hidden string() {
		while ($this.peek() -ne '"' -and !$this.isAtEnd()) {
			if ($this.peek() -eq "`n") { $this.Line += 1 }
			$this.advance()
		}

		if ($this.isAtEnd()) {
			[Lox]::error($this.Line, "Unterminated string.")
			return
		}

		$this.advance()

		[string] $value = $this.Source.Substring($this.Start + 1, $this.Current - $this.Start - 2)
		$this.addToken([TokenType]::TOKEN_STRING, $value)
	}

	[bool] hidden static isDigit([char] $c) {
		return $c -match '\d'
	}

	[void] hidden number() {
		while ([Scanner]::isDigit($this.peek())) {
			$this.advance()
		}

		if ($this.peek() -eq '.' -and [Scanner]::isDigit($this.peekNext())) {
			$this.advance()
			while ([Scanner]::isDigit($this.peek())) {
				$this.advance()
			}
		}

		$this.addToken([TokenType]::TOKEN_NUMBER, [double]($this.Source.Substring($this.Start, $this.Current - $this.Start)))
	}

	[bool] hidden static isAlpha([char] $c) {
		return $c -match '[a-zA-Z_]'
	}

	[bool] hidden static isAlphaNumeric([char] $c) {
		return $c -match '[a-zA-Z0-9_]'
	}

	[void] hidden identifier() {
		while ([Scanner]::isAlphaNumeric($this.peek())) {
			$this.advance()
		}
		[string] $text = $this.Source.Substring($this.Start, $this.Current - $this.Start)
		[TokenType] $type = if ([Scanner]::keywords.ContainsKey($text)) { [Scanner]::keywords[$text] } else { [TokenType]::TOKEN_IDENTIFIER }
		$this.addToken($type)
	}

	[char] hidden peek() {
		if ($this.isAtEnd()) { return "`0" }
		return $this.Source[$this.Current]
	}

	[char] hidden peekNext() {
		if ($this.Current + 1 -ge $this.Source.Length) { return "`0" }
		return $this.Source[$this.Current + 1]
	}


	# keywords

	[Dictionary[string, TokenType]] static $keywords

	static Scanner() {
		$values = [Dictionary[string, TokenType]]::new()
		
		@{
			"and"    = [TokenType]::TOKEN_AND
			"class"  = [TokenType]::TOKEN_CLASS
			"else"   = [TokenType]::TOKEN_ELSE
			"false"  = [TokenType]::TOKEN_FALSE
			"for"    = [TokenType]::TOKEN_FOR
			"fun"    = [TokenType]::TOKEN_FUN
			"if"     = [TokenType]::TOKEN_IF
			"nil"    = [TokenType]::TOKEN_NIL
			"or"     = [TokenType]::TOKEN_OR
			"print"  = [TokenType]::TOKEN_PRINT
			"return" = [TokenType]::TOKEN_RETURN
			"super"  = [TokenType]::TOKEN_SUPER
			"this"   = [TokenType]::TOKEN_THIS
			"true"   = [TokenType]::TOKEN_TRUE
			"var"    = [TokenType]::TOKEN_VAR
			"while"  = [TokenType]::TOKEN_WHILE
		}.GetEnumerator() | ForEach-Object {
			$values.Add($_.Name, $_.Value)
		}


		[Scanner]::keywords = $values

	}

}
