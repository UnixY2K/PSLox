using module .\LoxCallable.psm1
using module .\LoxFunction.psm1
using module .\Interpreter.psm1
using module .\LoxInstance.psm1

using namespace System.Collections.Generic

class LoxClass: LoxCallable {
	[string] $name
	[Dictionary[string, LoxFunction]] hidden $methods = [Dictionary[string, LoxFunction]]::new()

	LoxClass([string] $name, [Dictionary[string, LoxFunction]] $methods) {
		$this.name = $name
		$this.methods = $methods
	}

	[LoxFunction] findMethod([string] $name) {
		if ($this.methods.ContainsKey($name)) {
			return $this.methods[$name]
		}
		return $null
	}

	[Object] call([Interpreter] $interpreter, [List[Object]] $arguments) {
		[LoxInstance] $instance = [LoxInstance]::new($this)
		return $instance
	}

	[int] arity() {
		return 0
	}

	
	[string] ToString() {
		return $this.name
	}
}
