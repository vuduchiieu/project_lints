import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:project_lints/rules/prefer_context_extensions.dart';
import 'package:project_lints/rules/prefer_dot_shorthand.dart';
import 'package:project_lints/rules/prefer_num_extensions.dart';
import 'package:project_lints/rules/prefer_string_extension.dart';
import 'package:project_lints/rules/prefer_tap_extension.dart';

PluginBase createPlugin() => _ProjectLints();

class _ProjectLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    PreferContextExtensionsRule(),
    PreferNumExtensionsRule(),
    PreferStringExtension(),
    PreferTapExtensionRule(),
    PreferDotShorthandRule(),
  ];
}
