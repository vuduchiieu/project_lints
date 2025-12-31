import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferDotShorthandRule extends DartLintRule {
  PreferDotShorthandRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_dot_shorthand',
    problemMessage:
        '🚫 Dùng dot shorthand syntax (.contain thay vì BoxFit.contain)',
    errorSeverity: .ERROR,
  );

  static const _flutterEnums = {
    'BoxFit',
    'HitTestBehavior',
    'FilterQuality',
    'Alignment',
    'MainAxisAlignment',
    'CrossAxisAlignment',
    'MainAxisSize',
    'BlendMode',
    'Clip',
    'TextAlign',
    'TextDirection',
    'TextOverflow',
    'FontWeight',
    'FontStyle',
    'TextBaseline',
    'TextDecoration',
    'TextDecorationStyle',
    'Brightness',
    'Axis',
    'VerticalDirection',
    'StackFit',
    'FlexFit',
    'WrapAlignment',
    'WrapCrossAlignment',
    'ScrollPhysics',
    'ScrollDirection',
    'DragStartBehavior',
    'ImageRepeat',
    'TileMode',
    'MaterialTapTargetSize',
    'SnackBarBehavior',
    'FloatingActionButtonLocation',
    'NavigationRailLabelType',
    'TabBarIndicatorSize',
  };

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      final prefix = node.prefix;

      final enumName = prefix.name;

      if (!_flutterEnums.contains(enumName)) return;

      if (_canUseShorthand(node)) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addPropertyAccess((node) {
      final target = node.target;
      if (target is! SimpleIdentifier) return;

      final enumName = target.name;

      if (!_flutterEnums.contains(enumName)) return;

      if (_canUseShorthand(node)) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _canUseShorthand(AstNode node) {
    final parent = node.parent;

    if (parent is NamedExpression) return true;

    if (parent is VariableDeclaration) return true;

    if (parent is DefaultFormalParameter) return true;

    if (parent is ReturnStatement) return true;
    if (parent is ListLiteral || parent is SetOrMapLiteral) return true;
    if (parent is ArgumentList) return true;

    return false;
  }

  @override
  List<Fix> getFixes() => [_ReplaceWithShorthand()];
}

class _ReplaceWithShorthand extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;

      final enumValue = node.identifier.name;
      final replacement = '.$enumValue';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Thay thế bằng $replacement',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.sourceRange, replacement);
      });
    });

    context.registry.addPropertyAccess((node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;

      final enumValue = node.propertyName.name;
      final replacement = '.$enumValue';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Thay thế bằng $replacement',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.sourceRange, replacement);
      });
    });
  }
}
