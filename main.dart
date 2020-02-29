import 'src/lox.dart';

main(List<String> argv) {
	Lox lox = new Lox(argv);

	if (argv.length > 2) {
		print("Usage: dlox [script] [script_arg]");
	} else if (argv.length > 0) {
		lox.runFile(argv[0]);
	} else {
		lox.prompt();
	}
}