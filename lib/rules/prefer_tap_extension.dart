import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferTapExtensionRule extends DartLintRule {
  PreferTapExtensionRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_tap_extension',
    problemMessage: '🚫 Dùng .tap() extension thay vì GestureDetector',
    errorSeverity: .WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      // ✅ CHỈ check GestureDetector, BỎ QUA InkWell, InkResponse, etc
      final constructorName = node.constructorName.toString();

      if (!constructorName.startsWith('GestureDetector')) return;

      final args = node.argumentList.arguments;
      bool hasOnTap = false;
      bool hasChild = false;
      int argCount = 0;

      for (final arg in args) {
        if (arg is NamedExpression) {
          final name = arg.name.label.name;
          if (name == 'onTap') hasOnTap = true;
          if (name == 'child') hasChild = true;
          argCount++;
        }
      }

      // Only report if it's simple GestureDetector with onTap + child
      if (hasOnTap && hasChild && argCount <= 3) {
        reporter.atNode(node, _code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_ReplaceWithTapExtension()];
}

class _ReplaceWithTapExtension extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;

      final constructorName = node.constructorName.toString();
      if (!constructorName.startsWith('GestureDetector')) return;

      final args = node.argumentList.arguments;
      String? onTapValue;
      String? childValue;

      for (final arg in args) {
        if (arg is NamedExpression) {
          final name = arg.name.label.name;
          if (name == 'onTap') {
            onTapValue = arg.expression.toString();
          } else if (name == 'child') {
            childValue = arg.expression.toString();
          }
        }
      }

      if (onTapValue != null && childValue != null) {
        final replacement = '$childValue.tap($onTapValue)';

        final changeBuilder = reporter.createChangeBuilder(
          message: 'Thay thế bằng .tap() extension',
          priority: 80,
        );

        changeBuilder.addDartFileEdit((builder) {
          builder.addSimpleReplacement(node.sourceRange, replacement);
        });
      }
    });
  }
}
