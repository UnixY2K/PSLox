using module .\Interpreter.psm1
using module ..\Lox\Stmt.psm1


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
		
		$interpreter.executeBlock($this.declaration.body, $environment)
		return $null
	}

	[string] ToString() {
		return "<fn $($this.declaration.name.lexeme)>"
	}
}

class NativeLoxCallable: LoxCallable {
	[int] $arity = 0
	[scriptblock] $functionBlock = {}
	
	NativeLoxCallable([int] $arity, [scriptblock]$functionBlock) {
		$this.functionBlock = $functionBlock
		$this.arity = $arity
	}

	[int] arity() { return $this.arity }
	[Object] call([Interpreter]$interpreter, [List[Object]]$arguments) {
		if ($null -ne $this.functionBlock) {
			return $this.functionBlock.Invoke($interpreter, $arguments)
		}
		return $null
	}

	[string] ToString() {
		return "<native fn>"
	}

}
