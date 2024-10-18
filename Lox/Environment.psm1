using module .\Token.psm1
using module .\RuntimeError.psm1

class Environment {
	[hashtable] $values = @{}

	[object] get([Token] $name) {
		if ($this.values.ContainsKey($name.lexeme)) {
			return $this.values[$name.lexeme]
		}

		throw [RuntimeError]::new($name, "Undefined variable '$($name.lexeme)'.")
	}

	[void] define([string] $name, $value) {
		$this.values[$name] = $value
	}
}
