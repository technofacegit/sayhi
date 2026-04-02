import 'package:flutter/widgets.dart';
import 'package:qr_dating_app/l10n/app_localizations.dart';

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
