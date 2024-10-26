using module .\LoxCallable.psm1
using module .\Interpreter.psm1
using module .\LoxInstance.psm1
using module .\Jump.psm1
using module ..\Lox\Stmt.psm1
using module ..\Lox\RuntimeError.psm1

using namespace System.Collections.Generic

class LoxFunction: LoxCallable {
	[Function] hidden $declaration = $null
	[Environment] hidden $closure = $null
	[bool] hidden $isInitializer = $false

	LoxFunction([Function]$declaration, [Environment]$closure, [bool]$isInitializer) {
		$this.declaration = $declaration
		$this.closure = $closure
		$this.isInitializer = $isInitializer
	}

	[LoxFunction] bind([LoxInstance]$instance) {
		[Environment] $environment = [Environment]::new($this.closure)
		$environment.defineValue("this", $instance)
		return [LoxFunction]::new($this.declaration, $environment, $this.isInitializer)
	}

	[int] arity() { return $this.declaration.params.Count }

	[Object] call([Interpreter]$interpreter, [List[Object]]$arguments) {
		[Environment] $environment = [Environment]::new($this.closure)
		for ($i = 0; $i -lt $this.declaration.params.Count; $i++) {
			$environment.defineValue($this.declaration.params[$i].lexeme, $arguments[$i])
		}
		
		try {
			return $interpreter.executeBlock($this.declaration.body, $environment)
		}
		catch [JumpResultException] {
			[JumpResultException] $ex = $_.Exception
			switch ($ex.type) {
				J_Return {
					if ($this.isInitializer) { return $this.closure.getAt(0, "this") } 
					return $ex.value 
				}
				J_Continue { throw [RuntimeError]::new($ex.getToken(), "$($ex.typeToString()) is not inside a loop") }
				J_Break { throw [RuntimeError]::new($ex.getToken(), "$($ex.typeToString()) is not inside control structure") }
				default { throw [RuntimeError]::new($ex.getToken(), "$($ex.typeToString()) is not a valid jump statement") }
			}
		}
		if ($this.isInitializer) { return $this.closure.getAt(0, "this") }
		return $null
	}

	[string] ToString() {
		if ($null -eq $this.declaration.name) { return "<lambda fn>" }
		return "<fn $($this.declaration.name.lexeme)>"
	}
}
