using module .\Interpreter.psm1
using module .\Jump.psm1
using module ..\Lox\Stmt.psm1
using module ..\Lox\RuntimeError.psm1


using namespace System.Collections.Generic

class LoxCallable {

	[int] arity() { return $null }
	[Object] call([Interpreter]$interpreter, [List[Object]]$arguments) { return $null }

	[string] ToString() {
		return "<fn>"
	}
}

class LoxFunction: LoxCallable {
	[Function] hidden $declaration = $null

	LoxFunction([Function]$declaration) {
		$this.declaration = $declaration
	}

	[int] arity() { return $this.declaration.params.Count }

	[Object] call([Interpreter]$interpreter, [List[Object]]$arguments) {
		[Environment] $environment = [Environment]::new($interpreter.globals)
		for ($i = 0; $i -lt $this.declaration.params.Count; $i++) {
			$environment.define($this.declaration.params[$i].lexeme, $arguments[$i])
		}
		
		try {
			return $interpreter.executeBlock($this.declaration.body, $environment)
		}
		catch [JumpResultException] {
			[JumpResultException] $ex = $_.Exception
			switch ($ex.type) {
				J_Return { return $ex.value }
				J_Continue { throw [RuntimeError]::new($ex.getToken(), "$($ex.typeToString()) is not inside a loop") }
				J_Break { throw [RuntimeError]::new($ex.getToken(), "$($ex.typeToString()) is not inside control structure") }
				default { throw [RuntimeError]::new($ex.getToken(), "$($ex.typeToString()) is not a valid jump statement") }
			}
		}
		return $null
	}

	[string] ToString() {
		return "<fn $($this.declaration.name.lexeme)>"
	}
}

class NativeLoxCallable: LoxCallable {
	[int] hidden $m_arity = 0
	[scriptblock] $m_functionBlock = {}
	
	NativeLoxCallable([int] $arity, [scriptblock]$functionBlock) {
		$this.m_functionBlock = $functionBlock
		$this.m_arity = $arity
	}

	[int] arity() { return $this.m_arity }
	[Object] call([Interpreter]$interpreter, [List[Object]]$arguments) {
		if ($null -ne $this.m_functionBlock) {
			return Invoke-Command -ScriptBlock $this.m_functionBlock -ArgumentList $interpreter, $arguments
		}
		return $null
	}

	[string] ToString() {
		return "<native fn>"
	}

}
