import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferTapExtensionRule extends DartLintRule {
  PreferTapExtensionRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_tap_extension',
    problemMessage:
        '🚫 Dùng .tap() extension thay vì GestureDetector/InkWell/InkResponse',
    errorSeverity: .ERROR,
  );

  static const _bannedWidgets = {'GestureDetector', 'InkWell', 'InkResponse'};

  static const _allowedWidgets = {
    'TextButton',
    'ElevatedButton',
    'OutlinedButton',
    'IconButton',
    'FloatingActionButton',
    'PopupMenuButton',
    'DropdownButton',
    'MenuItemButton',
  };

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final constructorName = node.constructorName.toString();

      if (_allowedWidgets.any((w) => constructorName.startsWith(w))) {
        return;
      }

      final isBanned = _bannedWidgets.any(
        (widget) => constructorName.startsWith(widget),
      );

      if (!isBanned) return;

      final args = node.argumentList.arguments;
      bool hasOnTap = false;
      bool hasChild = false;
      int argCount = 0;
      Expression? onTapExpression;

      for (final arg in args) {
        if (arg is NamedExpression) {
          final name = arg.name.label.name;
          if (name == 'onTap' || name == 'onPressed') {
            hasOnTap = true;
            onTapExpression = arg.expression;
          }
          if (name == 'child') hasChild = true;
          argCount++;
        }
      }

      if (onTapExpression != null && _isUnfocusCallback(onTapExpression)) {
        return;
      }

      if (hasOnTap && hasChild && argCount <= 4) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _isUnfocusCallback(Expression expr) {
    if (expr is FunctionExpression) {
      final body = expr.body;

      if (body is ExpressionFunctionBody) {
        return _isUnfocusExpression(body.expression);
      }

      if (body is BlockFunctionBody) {
        final statements = body.block.statements;
        if (statements.length == 1) {
          final stmt = statements.first;
          if (stmt is ExpressionStatement) {
            return _isUnfocusExpression(stmt.expression);
          }
        }
      }
    }

    return false;
  }

  bool _isUnfocusExpression(Expression expr) {
    if (expr is MethodInvocation) {
      final methodName = expr.methodName.name;

      if (methodName == 'unfocus') {
        return true;
      }

      final target = expr.target;
      if (target is MethodInvocation && target.methodName.name == 'of') {
        final targetTarget = target.target;
        if (targetTarget is Identifier && targetTarget.name == 'FocusScope') {
          return true;
        }
      }
    }

    return false;
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

      final isBanned = PreferTapExtensionRule._bannedWidgets.any(
        (widget) => constructorName.startsWith(widget),
      );

      if (!isBanned) return;

      final args = node.argumentList.arguments;
      String? onTapValue;
      String? childValue;

      for (final arg in args) {
        if (arg is NamedExpression) {
          final name = arg.name.label.name;
          if (name == 'onTap' || name == 'onPressed') {
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
