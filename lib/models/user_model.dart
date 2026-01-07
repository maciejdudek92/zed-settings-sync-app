import 'dart:io';

import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

@Entity()
class UserModel {
  @Id()
  String? githubToken;
  late String zedSettingPath;
  DateTime? lastSync;
  String? repositoryId;

  UserModel() {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      zedSettingPath = p.join(home!, '.config', 'zed', 'settings.json');
    }
    if (Platform.isWindows) {
      getApplicationSupportDirectory().then((directory) {
        final appData = Directory(directory.path).parent.parent.path;
        zedSettingPath = p.join(appData, 'Roaming', 'Zed', 'settings.json');
      });
    }
  }
}
