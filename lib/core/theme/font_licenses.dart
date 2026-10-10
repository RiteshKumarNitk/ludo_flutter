import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

///Adds the bundled fonts' SIL Open Font License texts to the app's
///"Open-source licenses" page (Flutter's LicenseRegistry).
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, asset) in const [
      ('Baloo 2', 'assets/fonts/OFL-Baloo2.txt'),
      ('Hind', 'assets/fonts/OFL-Hind.txt'),
    ]) {
      final text = await rootBundle.loadString(asset);
      yield LicenseEntryWithLineBreaks([family], text.replaceFirst('﻿', ''));
    }
  });
}
