#Requires -Version 7
using module ..\Lox\Scanner.psm1
using module ..\Lox\Lox.psm1
using module ..\Lox\AstPrinter.psm1
using module ..\Lox\Parser.psm1

param(
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$Script
)

function runFile([string]$path) {
	$script = Get-Content $path -Raw
	run($script)
}

function run([string]$source) {
	$scanner = [Scanner]::new($source)
	$tokens = $scanner.scanTokens()
	[Parser] $parser = [Parser]::new($tokens)
	[Expr] $expression = $parser.parse()

	# Stop if there was a syntax error.
	if ([Lox]::hadError) { return }

	Write-host ([AstPrinter]::new()).print($expression)
}


# check if the script is not empty
if ($Script) {
	runFile($Script)
	if ([Lox]::hadError) {
		throw "An error has ocurred while running the script"
	}
}
else {
	# do a repl loop
	Write-Host "Running in REPL mode"
	Write-Host "Use '#exit' or Exit() to exit" 
	while ($true) {
		Write-Host "PSLox> " -NoNewline
		$line = Read-Host
		switch ($line) {
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
					Default {
						Write-Warning "Unknown interpreter command: $line"
					}
				}
			}
			Default {
				run($line)
				[Lox]::hadError = $false
			}
		}
        
	}
}
