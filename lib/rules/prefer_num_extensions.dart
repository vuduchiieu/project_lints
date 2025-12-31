import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferNumExtensionsRule extends DartLintRule {
  PreferNumExtensionsRule() : super(code: _baseCode);

  static final _baseCode = LintCode(
    name: 'prefer_num_extensions',
    problemMessage: 'Prefer num extensions',
    errorSeverity: .ERROR,
  );

  LintCode _code({required String from, required String to}) {
    return LintCode(
      name: 'prefer_num_extensions',
      problemMessage: '🚫 Không dùng $from, hãy dùng $to',
      errorSeverity: .ERROR,
    );
  }

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.staticType?.element?.name;

      if (typeName == 'SizedBox') {
        _checkSizedBox(node, reporter);
      } else if (typeName == 'Duration') {
        _checkDuration(node, reporter);
      }
    });
  }

  void _checkSizedBox(
    InstanceCreationExpression node,
    DiagnosticReporter reporter,
  ) {
    final args = node.argumentList.arguments;

    for (final arg in args) {
      if (arg is NamedExpression && arg.name.label.name == 'child') {
        return;
      }
    }

    for (final arg in args) {
      if (arg is! NamedExpression) continue;

      final name = arg.name.label.name;
      final expr = arg.expression;

      if ((name == 'height' || name == 'width') && _isSimpleNumber(expr)) {
        final value = expr.toString();
        final to = name == 'height' ? '$value.h' : '$value.w';

        reporter.atNode(node, _code(from: 'SizedBox($name: $value)', to: to));
        return;
      }
    }
  }

  void _checkDuration(
    InstanceCreationExpression node,
    DiagnosticReporter reporter,
  ) {
    final args = node.argumentList.arguments;
    if (args.length != 1) return;

    final arg = args.first;
    if (arg is! NamedExpression) return;

    final name = arg.name.label.name;
    final expr = arg.expression;

    if (!_isSimpleNumber(expr)) return;

    final value = expr.toString();

    if (name == 'milliseconds') {
      reporter.atNode(
        node,
        _code(from: 'Duration(milliseconds: $value)', to: '$value.ms'),
      );
    } else if (name == 'seconds') {
      reporter.atNode(
        node,
        _code(from: 'Duration(seconds: $value)', to: '$value.seconds'),
      );
    }
  }

  bool _isSimpleNumber(Expression expr) {
    if (expr is IntegerLiteral || expr is DoubleLiteral) return true;

    if (expr is MethodInvocation) {
      final target = expr.target;
      if (target is IntegerLiteral || target is DoubleLiteral) {
        return true;
      }
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

      final typeName = node.staticType?.element?.name;
      String? replacement;

      if (typeName == 'SizedBox') {
        replacement = _getSizedBoxReplacement(node);
      } else if (typeName == 'Duration') {
        replacement = _getDurationReplacement(node);
      }

      if (replacement == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Thay thế bằng $replacement',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.sourceRange, replacement!);
      });
    });
  }

  String? _getSizedBoxReplacement(InstanceCreationExpression node) {
    final args = node.argumentList.arguments;

    for (final arg in args) {
      if (arg is NamedExpression && arg.name.label.name == 'child') {
        return null;
      }
    }

    for (final arg in args) {
      if (arg is! NamedExpression) continue;

      final name = arg.name.label.name;
      final value = arg.expression.toString();

      if (name == 'height') return '$value.h';
      if (name == 'width') return '$value.w';
    }

    return null;
  }

  String? _getDurationReplacement(InstanceCreationExpression node) {
    final args = node.argumentList.arguments;
    if (args.length != 1) return null;

    final arg = args.first;
    if (arg is! NamedExpression) return null;

    final name = arg.name.label.name;
    final value = arg.expression.toString();

    if (name == 'milliseconds') return '$value.ms';
    if (name == 'seconds') return '$value.seconds';

    return null;
  }
}
