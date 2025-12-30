import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferContextFocusRule extends DartLintRule {
  PreferContextFocusRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_context_focus',
    problemMessage:
        '🚫 Dùng context.unfocus() thay vì FocusScope.of(context).unfocus()',
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
      if (target is! Identifier || target.name != 'FocusScope') return;

      final parent = node.parent;
      if (parent is PropertyAccess) {
        final grandParent = parent.parent;
        if (grandParent is MethodInvocation &&
            grandParent.methodName.name == 'unfocus') {
          reporter.atNode(grandParent, _code);
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_ReplaceWithContextFocus()];
}

class _ReplaceWithContextFocus extends DartFix {
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
      if (target is! Identifier || target.name != 'FocusScope') return;

      final parent = node.parent;
      if (parent is! PropertyAccess) return;

      final grandParent = parent.parent;
      if (grandParent is! MethodInvocation ||
          grandParent.methodName.name != 'unfocus')
        return;

      final contextArg = node.argumentList.arguments.first.toString();
      final replacement = '$contextArg.unfocus()';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Thay thế bằng $replacement',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(grandParent.sourceRange, replacement);
      });
    });
  }
}
