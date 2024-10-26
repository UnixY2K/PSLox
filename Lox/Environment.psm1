using module .\Token.psm1
using module .\RuntimeError.psm1

using namespace System.Collections.Generic

class Environment {
	[Environment] hidden $enclosing
	[Dictionary[string, object]] hidden $values = [Dictionary[string, object]]::new()

	Environment() {
		$this.Init($null)
	}

	Environment([Environment] $enclosing) {
		$this.Init($enclosing)
	}

	hidden Init([Environment] $enclosing = $null) {
		$this.enclosing = $enclosing
	}

	[object] get([Token] $name) {
		if ($this.values.ContainsKey($name.lexeme)) {
			$value = $this.values[$name.lexeme]
			if ($value -eq [void]) {
				throw [RuntimeError]::new($name, "Uninitialized variable '$($name.lexeme)'.")
			}
			return $value
		}

		if ($null -ne $this.enclosing) {
			return $this.enclosing.get($name)
		}

		throw [RuntimeError]::new($name, "Undefined variable '$($name.lexeme)'.")
	}

	[void] assign([Token] $name, [object] $value) {
		if ($this.values.ContainsKey($name.lexeme)) {
			$this.values[$name.lexeme] = $value
			return
		}

		if ($null -ne $this.enclosing) {
			$this.enclosing.assign($name, $value)
			return
		}

		throw [RuntimeError]::new($name, "Undefined variable '$($name.lexeme)'.")
	}

	[void] defineValue([string] $name, [object]$value) {
		$this.values[$name] = $value
	}

	[Environment] ancestor([int] $distance) {
		$environment = $this
		for ($i = 0; $i -lt $distance; $i++) {
			$environment = $environment.enclosing
		}
		return $environment
	}

	[Object] getAt([int] $distance, [string] $name) {
		return $this.ancestor($distance).values[$name]
	}

	[void] assignAt([int] $distance, [Token] $name, [object] $value) {
		$this.ancestor($distance).values[$name.lexeme] = $value
	}
}
