import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:github/github.dart';
import 'package:zed_settings_sync_app/main.dart';
import 'package:zed_settings_sync_app/models/settings_model.dart';
import 'package:zed_settings_sync_app/services/database_service.dart';
import 'package:flutter_shell/flutter_shell.dart';

class GithubService {
  bool isInitialized = false;
  late final SettingsModel _settings;
  GitHub? _github;
  RepositoriesService? _repositoriesService;
  CurrentUser? _githubUser;
  Repository? _repository;
  String? _repositoryPath;

  get isAthenticated => _github?.auth != null;

  String get repositoryPath => _repositoryPath!;

  Future<void> initialize() async {
    _settings = locator<DatabaseService>().getSettings();
    if (_settings.githubToken != null) {
      await authenticate();
      isInitialized = true;
    }
  }

  Future<void> authenticate() async {
    _github = GitHub(auth: Authentication.bearerToken(_settings.githubToken!));
    _githubUser = await UsersService(_github!).getCurrentUser();
    _repositoriesService = RepositoriesService(_github!);

    try {
      _repository = await _repositoriesService!.getRepository(
        RepositorySlug(_githubUser!.login!, "zed-settings-sync"),
      );
      await pull();
    } catch (e) {
      if (e.runtimeType == RepositoryNotFound) {
        _repository = await _repositoriesService!.createRepository(
          CreateRepository("zed-settings-sync", private: true),
        );
      }
    }
    _repositoryPath = _settings.settingJsonPath.replaceAll("settings.json", "");

    if (Directory(p.join(_repositoryPath!, '.git')).existsSync()) {
      push();
    } else {
      _init();
    }
  }

  Future<void> _init() async {
    String initCommand =
        'cd $_repositoryPath && git init && git add . && git commit -m "first commit" && git branch -M main && git remote add origin ${_repository!.cloneUrl} && git push -u origin main';
    if (Platform.isWindows) {
      initCommand = initCommand.replaceAll("&&", ";");
    }
    await ShellExecutor.executeCommands([initCommand]);
  }

  Future<void> push() async {
    String addComminAndPushCommand =
        'cd $_repositoryPath && git add . && git commit -m "update" && git push';
    if (Platform.isWindows) {
      addComminAndPushCommand = addComminAndPushCommand.replaceAll("&&", ";");
    }

    await ShellExecutor.executeCommands([addComminAndPushCommand]);
  }

  Future<void> pull() async {
    String pullCommand = 'cd $_repositoryPath && git pull';
    if (Platform.isWindows) {
      pullCommand = pullCommand.replaceAll("&&", ";");
    }
    await ShellExecutor.executeCommands([pullCommand]);
  }
}
