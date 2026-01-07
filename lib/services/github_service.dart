import 'package:github/github.dart';

class GithubService {
  bool isInitialized = false;

  Future<void> initialize() async {
    isInitialized = true;
  }

  Future<void> sync() async {}
}
