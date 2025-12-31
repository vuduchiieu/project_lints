import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferStringExtension extends DartLintRule {
  PreferStringExtension() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_asset_extension',
    problemMessage:
        '🚫 Dùng .toSvg() hoặc .toImage() extension thay vì SvgPicture.asset() hoặc Image.asset()',
    errorSeverity: .ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final constructorName = node.constructorName.toString();

      if (constructorName.contains('SvgPicture.asset') ||
          constructorName.contains('Image.asset')) {
        reporter.atNode(node, _code);
      }
    });
  }
}
