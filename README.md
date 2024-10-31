# PSLox
PowerShell Implementation of Lox programming language.

This is a PowerShell implementation of the Lox programming language, a language created by Bob Nystrom in his book [Crafting Interpreters](https://craftinginterpreters.com/).

The interpreter is fully completed and have several of the features of the original set plus some of the included challenges.

not implemented features:
- **unused variables error**: I did not wanted to add this feature so some scripts can be debugged easily
- **static methods**: I wanted to follow the original Inheritance path, but powershell does not allow multiple inheritance and has several class limitations, could be implemented differently though.

### Requirements 

 - [PowerShell 7+](https://microsoft.com/PowerShell)

## Usage

the most easy way to use this Lox interpreter is to use the PSLox.ps1 script file available in the releases
without parameters it will start a REPL (Read Eval Print Loop) session, optionally you can pass the lox script file as a parameter to execute it.


## Building

Even though powershell has support for modules I did not make the script files able to run out of the bugs due to current module quirks in powershell such as module reload, for this reason while creating this interpreter I made a tool to amalgamate all the files, it is not very complex but you can check it our here [PSAmalgamate](https://github.com/UnixY2K/PSAmalgamate) keep in mind that this tool has some limitations as I made it for this specific interpreter.

> for specific instructions of how to use PSAmalgamate check its repo  

## hacking the interpreter

there is 2 directories which contain the following information

- Interpreter: Lox Interpreter related data such as the Resolver, Interpreter and main entry script
- Lox: Core Lox language data such as the scanner common classes and the parser

### adding additional native functions

you can create new functions by defining them in the constructor of the interpreter, the only function implemented is the clock function which returns the current time in seconds.
