import 'package:watcher/watcher.dart';
import 'package:zed_settings_sync_app/main.dart';
import 'package:zed_settings_sync_app/models/settings_model.dart';
import 'package:zed_settings_sync_app/services/database_service.dart';
import 'package:zed_settings_sync_app/services/github_service.dart';

class WatcherService {
  bool isInitialized = false;
  late final SettingsModel _settings;
  late final DirectoryWatcher watcher;

  Future<void> initialize() async {
    _settings = locator<DatabaseService>().getSettings();
    if (_settings.settingJsonPath.isNotEmpty) {
      watcher = DirectoryWatcher(
        locator<GithubService>().repositoryPath,
        // pollingDelay: Duration(minutes: 15),
      );
      isInitialized = true;
    }
  }
}
