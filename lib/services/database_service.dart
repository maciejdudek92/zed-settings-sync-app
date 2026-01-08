import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:objectbox/objectbox.dart';
import 'package:zed_settings_sync_app/models/settings_model.dart';
import 'package:zed_settings_sync_app/objectbox.g.dart';
// created by `flutter pub run build_runner build`

class DatabaseService {
  late final Store _store;
  late SettingsModel _settings;
  late final Box<SettingsModel> _box;
  bool isInitialized = false;

  Future<void> initialize() async {
    final docsDir = await getApplicationDocumentsDirectory();
    _store = await openStore(directory: p.join(docsDir.path, "db"));
    _box = _store.box<SettingsModel>();
    final settings = _box.getAll();
    if (settings.isEmpty) {
      _box.put(SettingsModel());
    }
    _settings = _box.get(1)!;
    isInitialized = true;
  }

  SettingsModel getSettings() => _settings;

  void update() {
    final newSettings = _box.put(_settings);
    _settings = _box.get(newSettings)!;
  }
}
