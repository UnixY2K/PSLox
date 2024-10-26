using module .\LoxClass.psm1
using module .\LoxFunction.psm1
using module ..\Lox\Token.psm1
using module ..\Lox\RuntimeError.psm1

using namespace System.Collections.Generic

class LoxInstance {
	[LoxClass] hidden $klass
	[Dictionary[string, Object]] hidden $fields = [Dictionary[string, Object]]::new()


	LoxInstance([LoxClass] $klass) {
		$this.klass = $klass
	}

	[Object] get([Token] $name) {
		if ($this.fields.ContainsKey($name.lexeme)) {
			return $this.fields[$name.lexeme]
		}

		[LoxFunction] $method = $this.klass.findMethod($name.lexeme)
		if ($null -ne $method) {
			return $method.bind($this)
		}

		throw [RuntimeError]::new($name, "Undefined property '" + $name.lexeme + "'.")
	}

	[void] set([Token] $name, [Object] $value) {
		$this.fields[$name.lexeme] = $value
	}

	[string] ToString() {
		return $this.klass.name + " instance"
	}
}
