import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:get_it/get_it.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zed_settings_sync_app/services/database_service.dart';
import 'package:zed_settings_sync_app/services/github_service.dart';
import 'package:zed_settings_sync_app/services/services_wrapper.dart';
import 'package:zed_settings_sync_app/services/watcher_service.dart';

final locator = GetIt.instance;
WindowOptions windowOptions = WindowOptions(
  size: Size(400, 450),
  center: true,
  backgroundColor: Colors.transparent,
  skipTaskbar: false,
  titleBarStyle: TitleBarStyle.hidden,
);

Future<void> configureServices() async {
  locator.registerSingletonAsync<DatabaseService>(() async {
    final service = DatabaseService();
    await service.initialize();
    return service;
  });

  locator.registerSingletonAsync<GithubService>(() async {
    final service = GithubService();
    await service.initialize();
    return service;
  }, dependsOn: [DatabaseService]);

  locator.registerSingletonAsync<WatcherService>(() async {
    final service = WatcherService();
    await service.initialize();
    return service;
  }, dependsOn: [DatabaseService, GithubService]);

  await locator.allReady();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await configureServices();
  await trayManager.setIcon(
    Platform.isWindows
        ? 'assets/icons/tray_icon.ico'
        : 'assets/icons/tray_icon.png',
  );
  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'sync_status',
        label: ServicesWrapper.isInitialized
            ? 'Status: active'
            : 'Status: inactive',
        disabled: true,
      ),
      MenuItem.separator(),
      MenuItem(key: 'settings', label: 'Settings'),
      MenuItem(key: 'force_push', label: 'Force push'),
      MenuItem(key: 'force_pull', label: 'Force pull'),
      MenuItem(key: 'exit', label: 'Exit'),
    ],
  );
  await trayManager.setContextMenu(menu);
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
    packageName: 'com.maciejdudek.zedsettingssync',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    windowManager.hide();
    return MaterialApp(
      title: 'Flutter Demo',
      // theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.transparent)),
      home: const MyHomePage(title: 'Zed Settings Sync'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with TrayListener, WindowListener {
  final _githubAccessTokenController = TextEditingController();
  final _settingsJsonPathController = TextEditingController();
  late StreamSubscription<FileSystemEvent> _watcherStream;
  bool isRunAtStartuEnable = false;

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    if (ServicesWrapper.isInitialized) {
      windowManager.hide();
    } else {
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setResizable(false);
        await windowManager.show();
        await windowManager.focus();
        await windowManager.setPreventClose(true);
      });
    }

    launchAtStartup.isEnabled().then((value) {
      setState(() {
        isRunAtStartuEnable = value;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _watcherStream.cancel();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    // do something, for example pop up the menu
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    // do something
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'settings') {
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setResizable(false);
        await windowManager.show();
        await windowManager.focus();
        await windowManager.setPreventClose(true);
      });
    } else if (menuItem.key == 'force_push') {
      locator<GithubService>().push();
    } else if (menuItem.key == 'force_pull') {
      locator<GithubService>().pull();
    } else if (menuItem.key == 'exit') {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    _settingsJsonPathController.text = locator<DatabaseService>()
        .getSettings()
        .settingJsonPath;
    _githubAccessTokenController.text =
        locator<DatabaseService>().getSettings().githubToken ?? "";
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,

        title: Row(
          children: [
            Text(widget.title),
            Spacer(),
            FButton.icon(
              child: const Icon(FIcons.x),
              onPress: () {
                windowManager.hide();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(50, 20, 50, 50),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            FTextField(
              control: FTextFieldControl.managed(
                controller: _githubAccessTokenController,
              ),
              style: (style) => style.copyWith(),
              label: const Text('GitHub Access Token'),
              textCapitalization: TextCapitalization.none,
              enabled: true,
              clearable: (value) => value.text.isNotEmpty,
              maxLines: 1,
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: .end,
              children: [
                Flexible(
                  child: FTextField(
                    control: FTextFieldControl.managed(
                      controller: _settingsJsonPathController,
                    ),
                    style: (style) => style.copyWith(),
                    label: const Text('Zed Settings File Path'),
                    hint: Platform.isWindows
                        ? "C:\\Users\\User\\AppData\\Roaming\\Zed\\settings.json"
                        : '~/.config/zed/settings.json',
                    textCapitalization: TextCapitalization.none,
                    enabled: true,
                    readOnly: true,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 8),
                FButton.icon(
                  child: const Icon(FIcons.folderOpen, size: 22),
                  onPress: () async {
                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles(
                          initialDirectory: locator<DatabaseService>()
                              .getSettings()
                              .settingJsonPath,
                          type: FileType.custom,
                          allowedExtensions: ['json'],
                        );
                    if (result?.files[0].path != null) {
                      _settingsJsonPathController.text = result!.files[0].path!;
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            FCheckbox(
              label: const Text('Run at statrup'),
              value: isRunAtStartuEnable,
              onChange: (value) async {
                setState(() {
                  isRunAtStartuEnable = value;
                });
              },
              enabled: true,
              autofocus: true,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                FButton(
                  style: FButtonStyle.primary(),
                  prefix: const Icon(FIcons.save),

                  mainAxisSize: MainAxisSize.max,
                  onPress: () async {
                    setState(() {
                      final settings = locator<DatabaseService>().getSettings();
                      settings.settingJsonPath =
                          _settingsJsonPathController.value.text;
                      settings.githubToken =
                          _githubAccessTokenController.value.text;
                      locator<DatabaseService>().update();
                    });
                    if (isRunAtStartuEnable) {
                      await launchAtStartup.enable();
                    } else {
                      await launchAtStartup.disable();
                    }
                  },
                  child: const Text('Save'),
                ),
                Spacer(),
                FButton(
                  style: FButtonStyle.primary(),
                  prefix: const Icon(FIcons.github),

                  mainAxisSize: MainAxisSize.max,
                  onPress:
                      locator<DatabaseService>().getSettings().githubToken !=
                              null ||
                          locator<GithubService>().isAthenticated
                      ? null
                      : () {
                          locator<GithubService>().authenticate();
                        },
                  child: Text(
                    locator<GithubService>().isAthenticated
                        ? 'Authenticated'
                        : 'Authenticate',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            FButton(
              style: FButtonStyle.primary(),
              prefix: Icon(
                locator<WatcherService>().isInitialized
                    ? FIcons.pause
                    : FIcons.play,
              ),

              mainAxisSize: MainAxisSize.max,
              onPress: () async {
                setState(() {
                  final watcher = locator<WatcherService>();
                  if (watcher.isInitialized) {
                    watcher.stop();
                  } else {
                    watcher.start();
                  }
                });
              },
              child: Text(
                locator<WatcherService>().isInitialized
                    ? 'Stop watcher'
                    : 'Start watcher',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
