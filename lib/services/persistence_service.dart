// File-based JSON persistence for the app state.
//
// Platform-aware paths:
//   Windows: %APPDATA%\se4x\companion_state.json
//   macOS:   ~/Library/Application Support/se4x/companion_state.json
//   Linux:   $XDG_CONFIG_HOME/se4x/companion_state.json (fallback ~/.config)

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/game_state.dart';

class PersistenceService {
  static const _fileName = 'companion_state.json';
  static const _dirName = 'se4x';

  Future<String> _resolveDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}${Platform.pathSeparator}$_dirName';
    }

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

  Future<File> _resolveFile() async {
    final dir = await _resolveDirectory();
    return File('$dir${Platform.pathSeparator}$_fileName');
  }

  /// Load the persisted app state, or null if none exists or it's corrupted.
  Future<AppState?> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) return null;
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return AppState.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Save the app state to disk.
  ///
  /// Uses a write-to-temp-then-rename pattern to avoid corrupting
  /// the save file if the process is killed mid-write.
  Future<void> save(AppState state) async {
    try {
      final file = await _resolveFile();
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final json = jsonEncode(state.toJson());
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(json);
      await tmp.rename(file.path);
    } catch (_) {
      // Best-effort save; caller already debounces. A transient failure
      // (disk full, permission) will be retried on the next state change.
    }
  }

  /// Delete the persisted state file.
  Future<void> clear() async {
    try {
      final file = await _resolveFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore errors during cleanup
    }
  }
}
