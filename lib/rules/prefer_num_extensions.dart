import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferNumExtensionsRule extends DartLintRule {
  PreferNumExtensionsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_num_extensions',
    problemMessage: '🚫 Dùng num extensions (.h, .w, .ms, .seconds)',
    errorSeverity: .ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final type = node.staticType;
      final typeName = type?.element?.name;

      // Check SizedBox
      if (typeName == 'SizedBox') {
        _checkSizedBox(node, reporter);
      }
      // Check Duration
      else if (typeName == 'Duration') {
        _checkDuration(node, reporter);
      }
    });
  }

  void _checkSizedBox(
    InstanceCreationExpression node,
    DiagnosticReporter reporter,
  ) {
    final args = node.argumentList.arguments;

    bool hasChild = false;
    bool hasHeightOrWidth = false;

    for (final arg in args) {
      if (arg is NamedExpression) {
        final paramName = arg.name.label.name;

        if (paramName == 'child') {
          hasChild = true;
        }

        if (paramName == 'height' || paramName == 'width') {
          final expression = arg.expression;
          if (_isSimpleNumber(expression)) {
            hasHeightOrWidth = true;
          }
        }
      }
    }

    // Chỉ báo lỗi khi KHÔNG có child và có height/width
    if (hasHeightOrWidth && !hasChild) {
      reporter.atNode(node, _code);
    }
  }

  void _checkDuration(
    InstanceCreationExpression node,
    DiagnosticReporter reporter,
  ) {
    final args = node.argumentList.arguments;

    // Chỉ check khi có ĐÚNG 1 argument
    if (args.length != 1) return;

    final arg = args.first;
    if (arg is! NamedExpression) return;

    final paramName = arg.name.label.name;

    // Chỉ check milliseconds hoặc seconds
    if (paramName != 'milliseconds' && paramName != 'seconds') return;

    final expression = arg.expression;

    // Chỉ báo lỗi nếu là số đơn giản
    if (_isSimpleNumber(expression)) {
      reporter.atNode(node, _code);
    }
  }

  bool _isSimpleNumber(Expression expr) {
    if (expr is IntegerLiteral || expr is DoubleLiteral) return true;

    if (expr is MethodInvocation) {
      final target = expr.target;
      if (target is IntegerLiteral || target is DoubleLiteral) return true;
    }

    return false;
  }

  @override
  List<Fix> getFixes() => [_ReplaceWithExtension()];
}

class _ReplaceWithExtension extends DartFix {
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

      final type = node.staticType;
      final typeName = type?.element?.name;

      String? replacement;

      if (typeName == 'SizedBox') {
        replacement = _getSizedBoxReplacement(node);
      } else if (typeName == 'Duration') {
        replacement = _getDurationReplacement(node);
      }

      if (replacement != null) {
        final changeBuilder = reporter.createChangeBuilder(
          message: 'Thay thế bằng $replacement',
          priority: 80,
        );

        changeBuilder.addDartFileEdit((builder) {
          builder.addSimpleReplacement(node.sourceRange, replacement ?? '');
        });
      }
    });
  }

  String? _getSizedBoxReplacement(InstanceCreationExpression node) {
    final args = node.argumentList.arguments;

    // Check nếu có child thì không replace
    for (final arg in args) {
      if (arg is NamedExpression && arg.name.label.name == 'child') {
        return null;
      }
    }

    for (final arg in args) {
      if (arg is NamedExpression) {
        final paramName = arg.name.label.name;
        final value = arg.expression.toString();

        if (paramName == 'height') {
          return '$value.h';
        } else if (paramName == 'width') {
          return '$value.w';
        }
      }
    }

    return null;
  }

  String? _getDurationReplacement(InstanceCreationExpression node) {
    final args = node.argumentList.arguments;
    if (args.length != 1) return null;

    final arg = args.first;
    if (arg is! NamedExpression) return null;

    final paramName = arg.name.label.name;
    final value = arg.expression.toString();

    if (paramName == 'milliseconds') {
      return '$value.ms';
    } else if (paramName == 'seconds') {
      return '$value.seconds';
    }

    return null;
  }
}
