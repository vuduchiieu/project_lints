import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class PreferDotShorthandRule extends DartLintRule {
  PreferDotShorthandRule() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_dot_shorthand',
    problemMessage: '🚫 Dùng dot shorthand syntax (.contain, .all(8))',
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
    'AlignmentGeometry',
  };

  static const _flutterStaticMembers = {
    'EdgeInsets',
    'EdgeInsetsGeometry',
    'BorderRadius',
    'BorderRadiusGeometry',
    'Radius',
    'Rect',
    'BoxShape',
    'MaterialStateProperty',
    'double',
  };

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      final source = node.toSource();
      if (source.startsWith('.')) return;

      final prefix = node.prefix;
      final className = prefix.name;

      if (!_startsWithUpperCase(className)) return;

      if (_isInSwitchCase(node)) {
        if (_flutterEnums.contains(className)) {
          reporter.atNode(node, _code);
        }
        return;
      }

      if (!_flutterEnums.contains(className) &&
          !_flutterStaticMembers.contains(className)) {
        return;
      }

      if (_canUseShorthand(node)) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addPropertyAccess((node) {
      final source = node.toSource();
      if (source.startsWith('.')) return;

      final target = node.target;
      if (target is! SimpleIdentifier) return;

      final className = target.name;

      if (!_startsWithUpperCase(className)) return;
      if (_isInSwitchCase(node)) {
        if (_flutterEnums.contains(className)) {
          reporter.atNode(node, _code);
        }
        return;
      }
      if (!_flutterEnums.contains(className) &&
          !_flutterStaticMembers.contains(className)) {
        return;
      }

      if (_canUseShorthand(node)) {
        reporter.atNode(node, _code);
      }
    });

    context.registry.addInstanceCreationExpression((node) {
      final source = node.toSource();
      if (source.startsWith('.')) return;

      final constructorName = node.constructorName;
      final type = constructorName.type;
      // ignore: deprecated_member_use
      final typeName = type.name2.toString();

      if (!_flutterStaticMembers.contains(typeName)) return;

      if (_canUseShorthandForConstructor(node)) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _startsWithUpperCase(String name) {
    if (name.isEmpty) return false;
    final firstChar = name[0];
    return firstChar == firstChar.toUpperCase() &&
        firstChar != firstChar.toLowerCase();
  }

  bool _isInSwitchCase(AstNode node) {
    AstNode? current = node;

    while (current != null) {
      if (current is SwitchCase) return true;
      if (current is SwitchPatternCase) return true;
      if (current is SwitchExpressionCase) return true;

      current = current.parent;
    }

    return false;
  }

  bool _canUseShorthand(AstNode node) {
    final parent = node.parent;

    if (parent is NamedExpression) return true;
    if (parent is VariableDeclaration) return true;
    if (parent is DefaultFormalParameter) return true;
    if (parent is ReturnStatement) return true;
    if (parent is ListLiteral || parent is SetOrMapLiteral) return true;
    if (parent is ArgumentList) return true;
    if (parent is ExpressionStatement) return true;

    return false;
  }

  bool _canUseShorthandForConstructor(AstNode node) {
    final parent = node.parent;

    if (parent is NamedExpression) return true;
    if (parent is VariableDeclaration) return true;
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

      final propertyName = node.propertyName.name;
      final replacement = '.$propertyName';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Thay thế bằng $replacement',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.sourceRange, replacement);
      });
    });

    context.registry.addInstanceCreationExpression((node) {
      if (!node.sourceRange.intersects(analysisError.sourceRange)) return;

      final constructorName = node.constructorName;
      final name = constructorName.name?.name;
      final args = node.argumentList.toString();

      if (name == null) return;

      final replacement = '.$name$args';

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
