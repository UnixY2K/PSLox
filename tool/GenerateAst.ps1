using namespace System.Collections.Generic

param(
	[parameter(Mandatory)]
	[string]$outputDir
)
$ErrorActionPreference = "Stop"
	
$global:previousBaseName = $null

function preprocessTypes(
	[parameter(Mandatory)]
	[string]$baseName,
	[parameter(Mandatory)]
	[string[]]$types
) {
	$processedClasses = [List[hashtable]]::new()
	foreach ($type in $types) {
		$className = $type.Split(":")[0].Trim()
		$fieldLines = $type.Split(":")[1].Trim()
		$fields = [List[hashtable]]::new()
		foreach ($field in $fieldLines.Split(",")) {
			$type, $name = $field.Trim().Split(" ")
			$fields.Add(@{
					Type = $type.Trim()
					Name = $name.Trim()
				})
		}
		$processedClass = @{
			Name   = $className
			Fields = $fields
		}
		$processedClasses.Add($processedClass)
	}
	return $processedClasses
}
function defineAst(
	[parameter(Mandatory)]
	[string]$outputDir,
	[parameter(Mandatory)]
	[string]$baseName,
	[parameter(Mandatory)]
	[string[]]$requiredModules,
	[parameter(Mandatory)]
	[AllowEmptyCollection()]
	[string[]]$requiredNamespaces,
	[parameter(Mandatory)]
	[string[]]$types
) {
	# convert to a more usable format first
	$processedClasses = preprocessTypes -baseName $baseName -types $types
	$path = Join-Path $outputDir "$baseName.psm1"
	try {
		$writer = New-Object System.IO.StreamWriter($path)
		$requiredModules | ForEach-Object {
			$writer.WriteLine("using module .\$_")
		}
		$requiredNamespaces | ForEach-Object {
			$writer.WriteLine("using namespace $_")
		}
		$writer.WriteLine("`n")
		defineVisitor -writer $writer -baseName $baseName -types $processedClasses
		$writer.WriteLine("class $baseName {")
		$writer.WriteLine("`t[Object] accept([${baseName}Visitor]`$Visitor) { return `$null }")
		$writer.WriteLine("}`n")
		
		foreach ($class in $processedClasses) {
			defineType -writer $writer -baseName $baseName -class $class
		}
		$writer.WriteLine()
	}
	catch {
		Write-Error "an error occurred: $_"
		throw $_
	}
	finally {
		$writer.Close()
	}
}


function defineType(
	[parameter(Mandatory)]
	[System.IO.StreamWriter]$writer,
	[parameter(Mandatory)]
	[string]$baseName,
	[parameter(Mandatory)]
	[hashtable]$class
) {
	$sb = [System.Text.StringBuilder]::new()
	[void]$sb.AppendLine("class $($class.Name) : $baseName {")
	foreach ($field in $class.fields) {
		[void]$sb.AppendLine("`t[$($field.Type)] hidden `$$($field.Name)")
	}
	[void]$sb.AppendLine("")

	# define constructor
	[void]$sb.Append("`t$($class.Name)(")
	$constructorParams = [System.Collections.Generic.List[string]]::new()
	foreach ($field in $class.fields) {
		[void]$constructorParams.Add("[$($field.Type)] `$$($field.Name)")
	}
	[void]$sb.Append($constructorParams -join ", ")
	[void]$sb.AppendLine(") {")
	foreach ($field in $class.fields) {
		[void]$sb.AppendLine("`t`t`$this.$($field.Name) = `$$($field.Name)")
	}
	[void]$sb.AppendLine("`t}")

	# define accept method
	[void]$sb.AppendLine("`t[Object] accept([${baseName}Visitor]`$Visitor) {")
	[void]$sb.AppendLine("`t`treturn `$Visitor.visit$($class.Name)${baseName}(`$this)")
	[void]$sb.AppendLine("`t}")

	[void]$sb.AppendLine("}")
	$writer.WriteLine($sb.ToString())
}

function defineVisitor(
	[parameter(Mandatory)]
	[System.IO.StreamWriter]$writer,
	[parameter(Mandatory)]
	[string]$baseName,
	[parameter(Mandatory)]
	[hashtable[]]$types
) {
	$writer.Write("class ${baseName}Visitor")
	if ($global:previousBaseName) {
		$writer.Write(" : ${global:previousBaseName}Visitor")
	}
	$global:previousBaseName = "${baseName}"
	$writer.WriteLine(" {")
	foreach ($type in $types) {
		$className = $type.Name
		$writer.WriteLine("`tvisit${className}${baseName}([${className}]`$${className}) {}")
	}
	$writer.WriteLine("}`n")
}

defineAst $outputDir "Expr" @("Token.psm1") @() @(
	"Ternary	: Expr cond, Expr left, Expr right",
	"Assign		: Token name, Expr value",
	"Binary		: Expr left, Token operator, Expr right",
	"Grouping	: Expr expression",
	"Literal	: Object value",
	"Unary		: Token operator, Expr right",
	"Variable	: Token name"
)

defineAst $outputDir "Stmt" @("Expr.psm1", "Token.psm1") @("System.Collections.Generic") @(
	"Block		: List[Stmt] statements",
	"Expression	: Expr expression",
	"Print		: Expr expression",
	"Var		: Token name, Expr initializer"
)
