import 'package:zed_settings_sync_app/main.dart';
import 'package:zed_settings_sync_app/services/database_service.dart';
import 'package:zed_settings_sync_app/services/github_service.dart';
import 'package:zed_settings_sync_app/services/watcher_service.dart';

class ServicesWrapper {
  final databaseService = locator<DatabaseService>();
  final githubService = locator<GithubService>();
  final watcherService = locator<WatcherService>();

  static void configureServices() {
    locator.registerLazySingleton<GithubService>(() => GithubService());
    locator.registerLazySingleton<DatabaseService>(() => DatabaseService());
    locator.registerLazySingleton<WatcherService>(() => WatcherService());
    locator.registerLazySingleton<ServicesWrapper>(() => ServicesWrapper());
  }

  bool isInitialized() {
    return databaseService.isInitialized &&
        githubService.isInitialized &&
        watcherService.isInitialized;
  }
}
