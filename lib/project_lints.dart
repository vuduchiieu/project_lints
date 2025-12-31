import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:project_lints/rules/no_sized_box_shrink.dart';
import 'package:project_lints/rules/prefer_context_focus.dart';
import 'package:project_lints/rules/prefer_context_media_query.dart';
import 'package:project_lints/rules/prefer_context_theme.dart';

PluginBase createPlugin() => _ProjectLints();

class _ProjectLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    NoSizedBoxShrinkRule(),
    PreferContextThemeRule(),
    PreferContextMediaQueryRule(),
    PreferContextFocusRule(),
    PreferContextThemeRule(),
    PreferContextMediaQueryRule(),
    PreferContextFocusRule(),
  ];
}
