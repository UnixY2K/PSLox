using module .\Interpreter.psm1


using namespace System.Collections.Generic

class LoxCallable {

	[int] arity() { return $null }
	[Object] call([Interpreter]$interpreter, [List[Object]]$arguments) { return $null }

	[string] ToString() {
		return "<fn>"
	}
}
