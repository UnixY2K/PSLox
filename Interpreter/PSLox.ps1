#Requires -Version 7
using module ..\Lox\Scanner.psm1

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
	foreach ($token in $tokens) {
		Write-Host $token.toString()
	}
}


# check if the script is not empty
if ($Script) {
	runFile($Script)
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
					Default {
						Write-Warning "Unknown interpreter command: $line"
					}
				}
			}
			Default {
				run($line)
			}
		}
        
	}
}
