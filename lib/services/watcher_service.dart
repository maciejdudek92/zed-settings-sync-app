import 'dart:async';
import 'dart:io';
import 'package:zed_settings_sync_app/main.dart';
import 'package:zed_settings_sync_app/models/settings_model.dart';
import 'package:zed_settings_sync_app/services/database_service.dart';
import 'package:zed_settings_sync_app/services/github_service.dart';

class WatcherService {
  late final SettingsModel _settings;
  late Stream<FileSystemEvent> watcher;

  StreamSubscription<FileSystemEvent>? _subscription;
  bool _isInitialized = false;

  bool get isInitialized => _subscription != null && _isInitialized;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _settings = locator<DatabaseService>().getSettings();
    }
    final isFolderExist = await Directory(
      locator<GithubService>().repositoryPath,
    ).exists();
    print(isFolderExist);
    if (isFolderExist) {
      watcher = Directory(_settings.settingFolderPath).watch();
      _isInitialized = true;
      start();
    }
  }

  void _sync(FileSystemEvent event) {
    locator<GithubService>().push();
  }

  void start() {
    if (_subscription != null) return;
    _subscription = watcher.listen(
      _sync,
      onError: (error) => print(error),
      onDone: () => stop(),
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
