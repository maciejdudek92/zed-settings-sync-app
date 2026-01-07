import 'package:zed_settings_sync_app/models/user_model.dart';

class DatabaseService {
  bool isInitialized = false;

  Future<void> initialize() async {
    isInitialized = true;
  }

  Future<UserModel> getUser() async => UserModel();
  UserModel user = UserModel();
}
