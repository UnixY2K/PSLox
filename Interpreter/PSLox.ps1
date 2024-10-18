#Requires -Version 7
using module ..\Lox\Scanner.psm1
using module ..\Lox\Lox.psm1
using module ..\Lox\AstPrinter.psm1
using module ..\Lox\Parser.psm1
using module .\Interpreter.psm1

using namespace System.Collections.Generic

param(
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$Script
)

function runFile([string]$path) {
	$script = Get-Content $path -Raw
	run($script)
	if ([Lox]::hadError) {
		return 65
	}
	if ([Lox]::hadRuntimeError) {
		return 70
	}
}

function run([string]$source, [Interpreter]$interpreter = [Interpreter]::new(), [bool]$showAST = $false) {
	$scanner = [Scanner]::new($source)
	$tokens = $scanner.scanTokens()
	[Parser] $parser = [Parser]::new($tokens)
	[List[Stmt]] $statements = $parser.parse()

	# Stop if there was a syntax error.
	if ([Lox]::hadError) { return }

	if ($showAST) {
		Write-host "#>AST>#" ([AstPrinter]::new()).print($expression)
	}
	$interpreter.interpret($statements)
}

# avoid scope leak
function main(
	[string]$Script
) {
	[Interpreter]$interpreter = [Interpreter]::new()

	# check if the script is not empty
	if ($Script) {
		runFile($Script)
	}
	else {
		[bool]$showAST = $false
		# do a repl loop
		Write-Host "Running in REPL mode"
		Write-Host "Use '#exit' or Exit() to exit" 
		while ($true) {
			Write-Host "PSLox> " -NoNewline
			$line = Read-Host
			switch ($line) {
				{ $null -eq $_ } {
					return
				}
				{ $_.StartsWith("#") } {
					$command = $_.Substring(1).ToLowerInvariant()
					switch ($command) {
						"exit" { 
							return
						}
						"clear" {
							Clear-Host
						}
						"help" {
							Write-Host "Use '#exit' or Exit() to exit" 
						}
						"ast" {
							$showAST = !$showAST
							Write-Host "now $($showAST ? "showing": "hiding") AST"
						}
						Default {
							Write-Warning "Unknown interpreter command: $line"
						}
					}
				}
				Default {
					run $line $interpreter $showAST
					[Lox]::hadError = $false
				}
			}
        
		}
	}

}

[int]$returnCode = main($Script) ?? 0
exit $returnCode
