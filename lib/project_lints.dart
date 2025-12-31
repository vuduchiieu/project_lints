import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:project_lints/rules/no_sized_box_shrink.dart';
import 'package:project_lints/rules/prefer_asset_extension.dart';
import 'package:project_lints/rules/prefer_context_focus.dart';
import 'package:project_lints/rules/prefer_context_media_query.dart';
import 'package:project_lints/rules/prefer_context_theme.dart';
import 'package:project_lints/rules/prefer_sized_box_extension.dart';
import 'package:project_lints/rules/prefer_tap_extension.dart';

PluginBase createPlugin() => _ProjectLints();

class _ProjectLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    // Widget rules
    NoSizedBoxShrinkRule(),
    PreferSizedBoxExtensionRule(),
    PreferTapExtensionRule(),
    PreferAssetExtensionRule(),

    // Context extension rules
    PreferContextThemeRule(),
    PreferContextMediaQueryRule(),
    PreferContextFocusRule(),
  ];
}
