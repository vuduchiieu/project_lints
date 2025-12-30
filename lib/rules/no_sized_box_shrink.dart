import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NoSizedBoxShrinkRule extends DartLintRule {
  NoSizedBoxShrinkRule() : super(code: _code);

  static const _code = LintCode(
    name: 'no_sized_box_shrink',
    problemMessage: '🚫 Không dùng SizedBox rỗng! Dùng context.empty thay thế',
    errorSeverity: .ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.toString();

      if (typeName != 'SizedBox') return;

      final constructorName = node.constructorName.name?.name;

      if (constructorName == 'shrink') {
        reporter.atNode(node, code);
        return;
      }

      if (constructorName == null) {
        final args = node.argumentList.arguments;

        if (args.isEmpty) {
          reporter.atNode(node, code);
          return;
        }

        double? width;
        double? height;

        for (final arg in args) {
          if (arg is NamedExpression) {
            final name = arg.name.label.name;
            final value = arg.expression;

            if (value is IntegerLiteral && value.value == 0) {
              if (name == 'width') width = 0;
              if (name == 'height') height = 0;
            } else if (value is DoubleLiteral && value.value == 0.0) {
              if (name == 'width') width = 0;
              if (name == 'height') height = 0;
            }
          }
        }

        if (width == 0 && height == 0) {
          reporter.atNode(node, code);
          return;
        }

        if ((width == 0 && height == null && args.length == 1) ||
            (height == 0 && width == null && args.length == 1)) {
          reporter.atNode(node, code);
          return;
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_ReplaceWithContextEmpty()];
}

class _ReplaceWithContextEmpty extends DartFix {
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

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Thay thế bằng context.empty',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.sourceRange, 'context.empty');
      });
    });
  }
}
