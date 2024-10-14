using module ./Token.psm1

class RuntimeError: System.Exception {
	[Token] $token
  
	RuntimeError([Token] $token, [string] $message): base($message) {
		$this.token = $token;
	}
}
