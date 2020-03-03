## TinyLang based on Lox lang

Dart implementation of Tiny lang
Compile with `dart2native main.dart -o bin/dlox`.

Implementations changes:
* Use `print` and `println` functions instead of `print` statements
* Added native functions `str` and `num` for variable type casting
* Use `let` instead of `var` for variable declarations.
* Added `break` support
* Added support for native array with call to `Array()` : `let array = Array();`
* Added support for lambda functions with syntax `fun (arg) {}`
* Added native function `exit(code)` to exit program
* Added native function `error(errorMessage)` to display an error message to stderr
* Added native function `throw(errorInstance)` to display an error message and exit program
* Added support for ternary operator (`?:`)
* Use `construct` instead of `init` as class constructor
* Use `:` instead of `<` for class inheritance
* Added support for static methods with keyword `static`
* Added support for class getter method
* Added modular programs support through modules importing with keyword `import`
* Added **standard library** implemented in a mix of TinyLang and Dart with error classes (**Error** and **RuntimeError** classes),  support for basic Math operations (**Math** class), basic collections (**List** and **Map** classes), basic file I/0 (**File**, **Stat** and **Directory** classes), basic string manipulations (**String** class) and basic I/O (**Stdin**, **Stdout** and **Repl** classes)