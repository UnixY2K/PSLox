using module .\Token.psm1
using module .\RuntimeError.psm1

class Environment {
	[Environment] hidden $enclosing
	[hashtable] $values = @{}

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
			return $this.values[$name.lexeme]
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

	[void] define([string] $name, $value) {
		$this.values[$name] = $value
	}
}
