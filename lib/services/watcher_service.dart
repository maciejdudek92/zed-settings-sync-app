import 'dart:io';

import 'package:watcher/watcher.dart';
import 'package:zed_settings_sync_app/main.dart';
import 'package:zed_settings_sync_app/models/settings_model.dart';
import 'package:zed_settings_sync_app/services/database_service.dart';
import 'package:zed_settings_sync_app/services/github_service.dart';

class WatcherService {
  bool isInitialized = false;
  late final SettingsModel _settings;
  late Stream<FileSystemEvent> watcher;

  Future<void> initialize() async {
    _settings = locator<DatabaseService>().getSettings();

    final isFileExist = await File(_settings.settingJsonPath).exists();
    if (isFileExist) {
      // watcher = DirectoryWatcher(
      //   locator<GithubService>().repositoryPath,
      //   // pollingDelay: Duration(minutes: 15),
      // );
      watcher = File(_settings.settingJsonPath).watch();
      // File(_settings.settingJsonPath).watch().listen((event) {
      //   print(event);
      // });
      isInitialized = true;
    }
  }
}
