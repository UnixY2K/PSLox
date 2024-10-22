using module .\LoxCallable.psm1
using module .\Interpreter.psm1


using namespace System.Collections.Generic

class LoxNativeFunction: LoxCallable {
	[int] hidden $m_arity = 0
	[scriptblock] $m_functionBlock = {}
	
	LoxNativeFunction([int] $arity, [scriptblock]$functionBlock) {
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
