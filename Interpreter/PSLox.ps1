#Require -Version 7
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Script
)

# check if the script is not empty
if ($Script) {
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

            }
        }
        
    }
}
