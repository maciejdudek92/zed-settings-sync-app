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
  late String settingFolderPath;
  DateTime? lastSync;
  String? repositoryId;

  SettingsModel() {
    if (Platform.isWindows) {
      settingFolderPath = p.join(Platform.environment['APPDATA']!, 'Zed');
      settingJsonPath = p.join(settingFolderPath, 'settings.json');
    } else {
      settingFolderPath = p.join(
        Platform.environment['HOME']!,
        '.config',
        'zed',
      );
      settingJsonPath = p.join(settingFolderPath, 'settings.json');
    }
  }
}
