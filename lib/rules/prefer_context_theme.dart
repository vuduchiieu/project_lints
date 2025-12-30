import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferContextThemeRule extends DartLintRule {
  PreferContextThemeRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_context_theme',
    problemMessage:
        '🚫 Dùng context.textTheme hoặc context.colors thay vì Theme.of(context)',
    errorSeverity: .ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'of') return;

      final target = node.target;
      if (target is! Identifier || target.name != 'Theme') return;

      final parent = node.parent;
      if (parent is! PropertyAccess) return;

      final property = parent.propertyName.name;

      if (property == 'textTheme') {
        reporter.atNode(parent, _code);
      } else if (property == 'colorScheme') {
        reporter.atNode(parent, _code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_ReplaceWithContextTheme()];
}

class _ReplaceWithContextTheme extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;

      final target = node.target;
      if (target is! Identifier || target.name != 'Theme') return;

      final parent = node.parent;
      if (parent is! PropertyAccess) return;

      final property = parent.propertyName.name;
      final contextArg = node.argumentList.arguments.first.toString();

      String? replacement;
      if (property == 'textTheme') {
        replacement = '$contextArg.textTheme';
      } else if (property == 'colorScheme') {
        replacement = '$contextArg.colors';
      }

      if (replacement != null) {
        final changeBuilder = reporter.createChangeBuilder(
          message: 'Thay thế bằng $replacement',
          priority: 80,
        );

        changeBuilder.addDartFileEdit((builder) {
          builder.addSimpleReplacement(parent.sourceRange, replacement ?? '');
        });
      }
    });
  }
}
