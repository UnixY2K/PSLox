using module .\TokenType.psm1

class Token {

	[TokenType]	hidden $Type
	[string]	hidden $Lexeme
	[object]	hidden $Literal
	[int]		hidden $Line

	Token() { $this.Init(@{}) }
	Token([hashtable]$Properties) { $this.Init($Properties) }
	Token([TokenType] $Type, [string] $Lexeme, [object] $Literal, [int] $Line) {
		$this.Init(@{
				Type    = $Type
				Lexeme  = $Lexeme
				Literal = $Literal
				Line    = $Line
			})
	}

	[void] Init([hashtable]$Properties) {
		foreach ($Property in $Properties.Keys) {
			$this.$Property = $Properties.$Property
		}
	}

	[string] ToString() {
		return "Token(Type=$($this.Type ?? "UNDEFINED"), Lexeme=$($this.Lexeme ?? "UNDEFINED"), Literal=$($this.Literal ?? "UNDEFINED"))"
	}

}
