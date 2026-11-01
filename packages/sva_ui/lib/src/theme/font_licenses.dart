import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the SIL Open Font License texts of the bundled fonts to the app's
/// licence page, as the licence requires. Call once at start-up.
void registerSvaFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in const [
      ('Fraunces', 'OFL-Fraunces.txt'),
      ('Inter', 'OFL-Inter.txt'),
    ]) {
      final text = await rootBundle.loadString('packages/sva_ui/fonts/$file');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}
