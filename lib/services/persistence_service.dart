// File-based JSON persistence for the app state.
//
// Platform-aware paths:
//   Windows: %APPDATA%\se4x\companion_state.json
//   macOS:   ~/Library/Application Support/se4x/companion_state.json
//   Linux:   $XDG_CONFIG_HOME/se4x/companion_state.json (fallback ~/.config)

import 'dart:convert';
import 'dart:io';

import '../models/game_state.dart';

class PersistenceService {
  static const _fileName = 'companion_state.json';
  static const _dirName = 'se4x';

  String _resolveDirectory() {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) return '$appData${Platform.pathSeparator}$_dirName';
      return '${Platform.environment['USERPROFILE']}${Platform.pathSeparator}AppData${Platform.pathSeparator}Roaming${Platform.pathSeparator}$_dirName';
    }

    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '/tmp';
      return '$home/Library/Application Support/$_dirName';
    }

    // Linux and others
    final xdgConfig = Platform.environment['XDG_CONFIG_HOME'];
    if (xdgConfig != null) return '$xdgConfig/$_dirName';
    final home = Platform.environment['HOME'] ?? '/tmp';
    return '$home/.config/$_dirName';
  }

  File _resolveFile() {
    final dir = _resolveDirectory();
    return File('$dir${Platform.pathSeparator}$_fileName');
  }

  /// Load the persisted app state, or null if none exists or it's corrupted.
  Future<AppState?> load() async {
    try {
      final file = _resolveFile();
      if (!await file.exists()) return null;
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return AppState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Save the app state to disk.
  Future<void> save(AppState state) async {
    final file = _resolveFile();
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final json = jsonEncode(state.toJson());
    await file.writeAsString(json);
  }

  /// Delete the persisted state file.
  Future<void> clear() async {
    try {
      final file = _resolveFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore errors during cleanup
    }
  }
}
