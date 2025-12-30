import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferContextMediaQueryRule extends DartLintRule {
  PreferContextMediaQueryRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_context_media_query',
    problemMessage:
        '🚫 Dùng context.width/height/viewInsets thay vì MediaQuery.of(context)',
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
      if (target is! Identifier || target.name != 'MediaQuery') return;

      final parent = node.parent;
      if (parent is! PropertyAccess) return;

      final property = parent.propertyName.name;

      if (property == 'size') {
        final grandParent = parent.parent;
        if (grandParent is PropertyAccess) {
          final sizeProperty = grandParent.propertyName.name;
          if (sizeProperty == 'width' || sizeProperty == 'height') {
            reporter.atNode(grandParent, _code);
          }
        }
      } else if (property == 'viewInsets') {
        final grandParent = parent.parent;
        if (grandParent is PropertyAccess) {
          final viewInsetsProperty = grandParent.propertyName.name;
          if (viewInsetsProperty == 'bottom') {
            reporter.atNode(grandParent, _code);
          }
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_ReplaceWithContextMediaQuery()];
}

class _ReplaceWithContextMediaQuery extends DartFix {
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
      if (target is! Identifier || target.name != 'MediaQuery') return;

      final parent = node.parent;
      if (parent is! PropertyAccess) return;

      final property = parent.propertyName.name;
      final contextArg = node.argumentList.arguments.first.toString();

      String? replacement;

      if (property == 'size') {
        final grandParent = parent.parent;
        if (grandParent is PropertyAccess) {
          final sizeProperty = grandParent.propertyName.name;
          if (sizeProperty == 'width') {
            replacement = '$contextArg.width';
          } else if (sizeProperty == 'height') {
            replacement = '$contextArg.height';
          }
        }
      } else if (property == 'viewInsets') {
        final grandParent = parent.parent;
        if (grandParent is PropertyAccess) {
          final viewInsetsProperty = grandParent.propertyName.name;
          if (viewInsetsProperty == 'bottom') {
            replacement = '$contextArg.viewInsets';
          }
        }
      }

      if (replacement != null) {
        final changeBuilder = reporter.createChangeBuilder(
          message: 'Thay thế bằng $replacement',
          priority: 80,
        );

        changeBuilder.addDartFileEdit((builder) {
          final parent = node.parent;
          if (parent is PropertyAccess) {
            final grandParent = parent.parent;
            if (grandParent is PropertyAccess) {
              builder.addSimpleReplacement(
                grandParent.sourceRange,
                replacement ?? '',
              );
            }
          }
        });
      }
    });
  }
}
