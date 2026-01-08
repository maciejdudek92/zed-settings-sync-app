import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:get_it/get_it.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zed_settings_sync_app/services/database_service.dart';
import 'package:zed_settings_sync_app/services/github_service.dart';
import 'package:zed_settings_sync_app/services/services_wrapper.dart';
import 'package:zed_settings_sync_app/services/watcher_service.dart';

final locator = GetIt.instance;
WindowOptions windowOptions = WindowOptions(
  size: Size(400, 400),
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
  await trayManager.setIcon('');
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
      MenuItem(key: 'exit_app', label: 'Exit App'),
    ],
  );
  await trayManager.setContextMenu(menu);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
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
  late StreamSubscription _watcherSubscription;
  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    _watcherSubscription = locator<WatcherService>().watcher.events.listen((
      event,
    ) {
      print(event);
      locator<GithubService>().sync();
    });
    super.initState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    _watcherSubscription.cancel();
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
    } else if (menuItem.key == 'exit_app') {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
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
    _settingsJsonPathController.text = locator<DatabaseService>()
        .getSettings()
        .settingJsonPath;
    _githubAccessTokenController.text =
        locator<DatabaseService>().getSettings().githubToken ?? "";
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.all(50),
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
            FTextField(
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
              maxLines: 1,
              onTap: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  initialDirectory: locator<DatabaseService>()
                      .getSettings()
                      .settingJsonPath,
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );
                _settingsJsonPathController.text = result?.files[0].path ?? '';
              },
            ),
            SizedBox(height: 24),
            Row(
              children: [
                FButton(
                  child: const Text('Save'),
                  style: FButtonStyle.primary(),
                  prefix: const Icon(FIcons.save),

                  mainAxisSize: MainAxisSize.max,
                  onPress: () {
                    setState(() {
                      final settings = locator<DatabaseService>().getSettings();
                      settings.settingJsonPath =
                          _settingsJsonPathController.value.text;
                      settings.githubToken =
                          _githubAccessTokenController.value.text;
                      locator<DatabaseService>().update();
                    });
                  },
                ),
                SizedBox(width: 10),
                FButton(
                  child: const Text('Authenticate'),
                  style: FButtonStyle.primary(),
                  prefix: const Icon(FIcons.github),

                  mainAxisSize: MainAxisSize.max,
                  onPress:
                      locator<DatabaseService>().getSettings().githubToken ==
                          null
                      ? null
                      : () {
                          locator<GithubService>().authenticate();
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
