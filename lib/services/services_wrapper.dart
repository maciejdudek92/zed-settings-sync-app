import 'package:zed_settings_sync_app/main.dart';
import 'package:zed_settings_sync_app/services/database_service.dart';
import 'package:zed_settings_sync_app/services/github_service.dart';
import 'package:zed_settings_sync_app/services/watcher_service.dart';

class ServicesWrapper {
  static bool isInitialized =
      locator<DatabaseService>().isInitialized &&
      locator<GithubService>().isInitialized &&
      locator<WatcherService>().isInitialized;
}
