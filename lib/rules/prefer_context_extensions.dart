import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferContextExtensionsRule extends DartLintRule {
  PreferContextExtensionsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_context_extensions',
    problemMessage: '🚫 Dùng context extensions thay vì gọi trực tiếp',
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
      if (target is! Identifier) return;

      final targetName = target.name;

      if (targetName == 'Theme') {
        _checkThemeUsage(node, reporter);
      } else if (targetName == 'MediaQuery') {
        _checkMediaQueryUsage(node, reporter);
      } else if (targetName == 'FocusScope') {
        _checkFocusScopeUsage(node, reporter);
      }
    });
  }

  void _checkThemeUsage(MethodInvocation node, DiagnosticReporter reporter) {
    final parent = node.parent;
    if (parent is! PropertyAccess) return;

    final property = parent.propertyName.name;

    if (property == 'textTheme') {
      reporter.atNode(parent, _code);
    } else if (property == 'platform') {
      reporter.atNode(parent, _code);
    }
  }

  void _checkMediaQueryUsage(
    MethodInvocation node,
    DiagnosticReporter reporter,
  ) {
    final parent = node.parent;
    if (parent is! PropertyAccess) return;

    final property = parent.propertyName.name;
    if (property == 'size') {
      final grandParent = parent.parent;
      if (grandParent is! PropertyAccess) return;

      final sizeProperty = grandParent.propertyName.name;

      if (sizeProperty == 'width') {
        reporter.atNode(grandParent, _code);
      } else if (sizeProperty == 'height') {
        reporter.atNode(grandParent, _code);
      }
    } else if (property == 'viewInsets') {
      final grandParent = parent.parent;
      if (grandParent is! PropertyAccess) return;

      final viewInsetsProperty = grandParent.propertyName.name;
      if (viewInsetsProperty == 'bottom') {
        reporter.atNode(grandParent, _code);
      }
    }
  }

  void _checkFocusScopeUsage(
    MethodInvocation node,
    DiagnosticReporter reporter,
  ) {
    final parent = node.parent;
    if (parent is PropertyAccess) {
      final grandParent = parent.parent;
      if (grandParent is MethodInvocation &&
          grandParent.methodName.name == 'unfocus') {
        reporter.atNode(grandParent, _code);
      }
    }
  }

  @override
  List<Fix> getFixes() => [_ReplaceWithContextExtension()];
}

class _ReplaceWithContextExtension extends DartFix {
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
      if (target is! Identifier) return;

      final targetName = target.name;
      String? replacement;

      if (targetName == 'Theme') {
        replacement = _getThemeReplacement(node);
      } else if (targetName == 'MediaQuery') {
        replacement = _getMediaQueryReplacement(node);
      } else if (targetName == 'FocusScope') {
        replacement = _getFocusScopeReplacement(node);
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
              // MediaQuery case
              builder.addSimpleReplacement(
                grandParent.sourceRange,
                replacement ?? '',
              );
            } else if (grandParent is MethodInvocation) {
              // FocusScope case
              builder.addSimpleReplacement(
                grandParent.sourceRange,
                replacement ?? '',
              );
            } else {
              builder.addSimpleReplacement(
                parent.sourceRange,
                replacement ?? '',
              );
            }
          }
        });
      }
    });
  }

  String? _getThemeReplacement(MethodInvocation node) {
    final parent = node.parent;
    if (parent is! PropertyAccess) return null;

    final property = parent.propertyName.name;
    final contextArg = node.argumentList.arguments.first.toString();

    if (property == 'textTheme') {
      return '$contextArg.textTheme';
    } else if (property == 'platform') {
      return '$contextArg.platform';
    }
    return null;
  }

  String? _getMediaQueryReplacement(MethodInvocation node) {
    final parent = node.parent;
    if (parent is! PropertyAccess) return null;

    final property = parent.propertyName.name;
    final contextArg = node.argumentList.arguments.first.toString();

    if (property == 'size') {
      final grandParent = parent.parent;
      if (grandParent is PropertyAccess) {
        final sizeProperty = grandParent.propertyName.name;
        if (sizeProperty == 'width') {
          return '$contextArg.width';
        } else if (sizeProperty == 'height') {
          return '$contextArg.height';
        }
      }
    } else if (property == 'viewInsets') {
      final grandParent = parent.parent;
      if (grandParent is PropertyAccess) {
        final viewInsetsProperty = grandParent.propertyName.name;
        if (viewInsetsProperty == 'bottom') {
          return '$contextArg.viewInsets';
        }
      }
    }
    return null;
  }

  String? _getFocusScopeReplacement(MethodInvocation node) {
    final parent = node.parent;
    if (parent is! PropertyAccess) return null;

    final grandParent = parent.parent;
    if (grandParent is! MethodInvocation) return null;

    if (grandParent.methodName.name != 'unfocus') return null;

    final contextArg = node.argumentList.arguments.first.toString();
    return '$contextArg.unfocus()';
  }
}
