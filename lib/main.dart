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

final locator = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  ServicesWrapper.configureServices();

  await trayManager.setIcon('assets/icons/tray_icon.png');
  Menu menu = Menu(
    items: [
      MenuItem(key: 'sync_status', label: 'Status: inactive', disabled: true),
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
  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    // do something, for example pop up the menu
    windowManager.show();
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
    if (menuItem.key == 'show_window') {
      // do something
    } else if (menuItem.key == 'exit_app') {
      // do something
    }
  }

  @override
  Widget build(BuildContext context) {
    if (locator<ServicesWrapper>().isInitialized()) {
      windowManager.hide();
    } else {
      WindowOptions windowOptions = WindowOptions(
        size: Size(400, 400),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setResizable(false);
        await windowManager.show();
        await windowManager.focus();
        await windowManager.setPreventClose(true);
      });
    }
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
                initial: TextEditingValue(
                  text: locator<DatabaseService>().user.githubToken ?? "",
                ),
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
                initial: TextEditingValue(
                  text: locator<DatabaseService>().user.zedSettingPath,
                ),
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
                  initialDirectory:
                      locator<DatabaseService>().user.zedSettingPath,
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );
              },
            ),
            SizedBox(height: 24),
            FButton(
              child: const Text('Save'),
              style: FButtonStyle.primary(),
              prefix: const Icon(FIcons.save),

              mainAxisSize: MainAxisSize.max,
              onPress: () {},
              onLongPress: () {},
              onSecondaryPress: () {},
              onSecondaryLongPress: () {},
              shortcuts: {
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              },
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {},
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
