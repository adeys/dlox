import 'src/lox.dart';

main(List<String> argv) {
	Lox lox = new Lox();

	if (argv.length > 1) {
    	print("Usage: dlox [script]");
	} else if (argv.length == 1) {
    	lox.runFile(argv[0]);
	} else {
		lox.prompt();
	}
}