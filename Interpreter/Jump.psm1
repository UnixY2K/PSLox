using module ..\Lox\Stmt.psm1
using module ..\Lox\RuntimeError.psm1
using module ..\Lox\Token.psm1

enum JumpType {
	J_Return
	J_Continue
	J_Break
	J_Unknown
}

class JumpResultException: System.Exception {
	[Jump] $stmt
	[JumpType] $type
	[object] $value
	JumpResultException([Jump] $stmt, [object]$value) : base () {
		$this.stmt = $stmt
		$this.type = ( & {
				switch ($stmt.keyword.type) {
					TOKEN_CONTINUE { return [JumpType]::J_Continue }
					TOKEN_BREAK { return [JumpType]::J_Break }
					TOKEN_RETURN { return [JumpType]::J_Return }
					default { throw [RuntimeError]::new($stmt.type, "Invalid jump type") }
				} })
		$this.value = $value
	}

	[Token] getToken() {
		return $this.stmt.keyword
	}

	[string] typeToString() {
		return (& { switch ($this.type) {
					J_Continue { return "continue" }
					J_Break { return "break" }
					J_Return { return "return" }
					default { return "unknown" }
				} })
	}
	
	[string] ToString() {
		return "$($this.typeToString())"
	}
}
