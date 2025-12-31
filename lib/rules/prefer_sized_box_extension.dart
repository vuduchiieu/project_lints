import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferSizedBoxExtensionRule extends DartLintRule {
  PreferSizedBoxExtensionRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_sized_box_extension',
    problemMessage:
        '🚫 Dùng extension .h hoặc .w thay vì SizedBox(height:) hoặc SizedBox(width:)',
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
      if (type?.element?.name != 'SizedBox') return;

      final args = node.argumentList.arguments;
      for (final arg in args) {
        if (arg is NamedExpression) {
          final paramName = arg.name.label.name;
          if (paramName == 'height' || paramName == 'width') {
            final expression = arg.expression;
            if (_isSimpleNumber(expression)) {
              reporter.atNode(node, _code);
              return;
            }
          }
        }
      }
    });
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

      final args = node.argumentList.arguments;
      for (final arg in args) {
        if (arg is NamedExpression) {
          final paramName = arg.name.label.name;
          final value = arg.expression.toString();

          String? replacement;
          if (paramName == 'height') {
            replacement = '$value.h';
          } else if (paramName == 'width') {
            replacement = '$value.w';
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
        }
      }
    });
  }
}
