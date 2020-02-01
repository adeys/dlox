import 'dart:io';

class AstGenerator {
	String file;
	
	AstGenerator(String file) {
		this.file = file;
	}

	void generate(StringBuffer buffer) {
		File out = new File(file);
		
		out.writeAsStringSync(buffer.toString());
	}

	void defineExpr(StringBuffer buffer, String base, List<String> types) {
		// Define imports
		buffer.writeln("import './tokens.dart';");
		buffer.writeln('');
		
		// Define base class
		buffer..writeln('abstract class $base {')
			..writeln('    accept(${base}Visitor visitor);')
			..writeln('}');

		// Define subclasses
		buffer.writeln('');
		types.forEach((String expr) {
			String name = expr.split(':')[0].trim();
			String types = expr.split(':')[1].trim();
			List<String> typesList = types.split(',');

			buffer.writeln('class ${name + base} extends $base {');
			typesList.forEach((String type) => buffer.writeln('	${type.trim()};'));
			buffer.writeln('');
			
			// Define constructor
			buffer.writeln('\t${name + base}($types) {');
			typesList.forEach((String type) {
				String param = type.trim().split(' ')[1];
				buffer.writeln('\t\tthis.$param = $param;');
			});
			buffer.writeln('\t}\n');

			// Define visitor
			buffer..writeln('\taccept(${base}Visitor visitor) {')
				..writeln('\t\treturn visitor.visit${name}${base}(this);')
				..writeln('\t}')

			..writeln('}\n\n');
		});
	}

	void defineVisitor(StringBuffer buffer, String base, List<String> types) {
		// Define base class
		buffer..writeln('abstract class ${base}Visitor {');

		// Define subclasses
		buffer.writeln('');
		types.forEach((String expr) {
			String name = expr.split(':')[0].trim();

			buffer..writeln('\tvisit${name}${base}(${name}${base} expr) {')
				..writeln('\t\treturn expr.accept(this);')
				..writeln('\t}');
			
			buffer.writeln('');
		});

		buffer.writeln('}');
	}

}