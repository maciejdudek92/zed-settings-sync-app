import 'package:watcher/watcher.dart';
import 'package:zed_settings_sync_app/main.dart';
import 'package:zed_settings_sync_app/services/database_service.dart';

class WatcherService {
  bool isInitialized = false;

  Future<void> initialize() async {
    isInitialized = true;
    final user = await locator<DatabaseService>().getUser();
    FileWatcher(user.zedSettingPath, pollingDelay: Duration(minutes: 15));
  }

  Future<void> sync() async {
    if (!isInitialized) {
      await initialize();
    }
  }

  WatcherService();
}
