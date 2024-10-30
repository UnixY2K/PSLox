using module .\LoxCallable.psm1
using module .\LoxFunction.psm1
using module .\Interpreter.psm1
using module .\LoxInstance.psm1

using namespace System.Collections.Generic

class LoxClass: LoxCallable {
	[string] $name
	[Dictionary[string, LoxFunction]] hidden $methods = [Dictionary[string, LoxFunction]]::new()
	[LoxClass] $superclass

	LoxClass([string] $name, [LoxClass]$superclass, [Dictionary[string, LoxFunction]] $methods) {
		$this.name = $name
		$this.superclass = $superclass
		$this.methods = $methods
	}

	[LoxFunction] findMethod([string] $name) {
		if ($this.methods.ContainsKey($name)) {
			return $this.methods[$name]
		}

		if ($null -ne $this.superclass) {
			return $this.superclass.findMethod($name)
		}
		
		return $null
	}

	[Object] call([Interpreter] $interpreter, [List[Object]] $arguments) {
		[LoxInstance] $instance = [LoxInstance]::new($this)
		[LoxFunction] $initializer = $this.findMethod("init")
		if ($null -ne $initializer) {
			$initializer.bind($instance).call($interpreter, $arguments)
		}
		return $instance
	}

	[int] arity() {
		[LoxFunction] $initializer = $this.findMethod("init")
		if ($null -ne $initializer) {
			return $initializer.arity()
		}
		return 0
	}

	
	[string] ToString() {
		return $this.name
	}
}
