import 'dart:io';

import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

@Entity()
class SettingsModel {
  @Id()
  int id = 1;
  String? githubToken;
  late String settingJsonPath;
  DateTime? lastSync;
  String? repositoryId;

  SettingsModel() {
    if (Platform.isWindows) {
      settingJsonPath = p.join(
        Platform.environment['APPDATA']!,
        'Zed',
        'settings.json',
      );
    } else {
      settingJsonPath = p.join(
        Platform.environment['HOME']!,
        '.config',
        'zed',
        'settings.json',
      );
    }
  }
}
