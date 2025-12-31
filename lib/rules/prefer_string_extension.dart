import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferStringExtension extends DartLintRule {
  PreferStringExtension() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_asset_extension',
    problemMessage:
        '🚫 Dùng .toSvg(), .toImage() hoặc .toCachedImg() extension thay vì SvgPicture.asset(), Image.asset() hoặc CachedNetworkImage.',
    errorSeverity: .ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final name = node.constructorName.toSource();

      if (name.startsWith('SvgPicture.asset') ||
          name.startsWith('Image.asset') ||
          name.startsWith('CachedNetworkImage')) {
        reporter.atNode(node, _code);
      }
    });
  }
}
