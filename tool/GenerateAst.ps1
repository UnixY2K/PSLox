param(
	[parameter(Mandatory)]
	[string]$outputDir
)
$ErrorActionPreference = "Stop"
	

function preprocessTypes(
	[parameter(Mandatory)]
	[string]$baseName,
	[parameter(Mandatory)]
	[string[]]$types
) {
	$processedClasses = [System.Collections.Generic.List[hashtable]]::new()
	foreach ($type in $types) {
		$className = $type.Split(":")[0].Trim()
		$fieldLines = $type.Split(":")[1].Trim()
		$fields = [System.Collections.Generic.List[hashtable]]::new()
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
	[string[]]$types
) {
	# convert to a more usable format first
	$processedClasses = preprocessTypes -baseName $baseName -types $types
	$path = Join-Path $outputDir "$baseName.psm1"
	try {
		$writer = New-Object System.IO.StreamWriter($path)
		$writer.WriteLine("using module .\Token.psm1`n`n")
		defineVisitor -writer $writer -baseName $baseName -types $processedClasses
		$writer.WriteLine("class $baseName {")
		$writer.WriteLine("`t[Object] accept([ExprVisitor]`$Visitor) { return `$null }")
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
	[void]$sb.AppendLine("`t[Object] accept([ExprVisitor]`$Visitor) {")
	[void]$sb.AppendLine("`t`treturn `$Visitor.visit$($class.Name)Expr(`$this)")
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
	$writer.WriteLine("class ${baseName}Visitor {")
	foreach ($type in $types) {
		$className = $type.Name
		$writer.WriteLine("`tvisit${className}Expr([${className}]`$${className}) {}")
	}
	$writer.WriteLine("}`n")
}

defineAst $outputDir "Expr" @(
	"Binary   : Expr left, Token operator, Expr right",
	"Grouping : Expr expression",
	"Literal  : Object value",
	"Unary    : Token operator, Expr right"
)
