using module .\Token.psm1
using module .\TokenType.psm1
using module .\RuntimeError.psm1

class Lox {
	static [boolean] $hadError = $false
	static [boolean] $hadRuntimeError = $false
	
	static [void] error([int] $line, [string] $message) {
		[Lox]::report($line, "", $message)
	}

	static [void] error([Token] $token, [string] $message) {
		if ($token.type -eq [TokenType]::TOKEN_EOF) {
			[Lox]::report($token.line, " at end", $message)
		}
		else {
			[Lox]::report($token.line, " at '$($token.lexeme)'", $message)
		}
	}

	static [void] hidden report([int] $line, [string] $where, [string] $message) {
		Write-Host "[line $line] Error${where}: $message" -ForegroundColor Red
		[Lox]::hadError = $true
	}

	static [void] runtimeError([RuntimeError] $err) {
		Write-Host "$($error.getMessage())\n[line $($error.token.line)]" -ForegroundColor Red
		[Lox]::hadRuntimeError = true;
	}

	
}
