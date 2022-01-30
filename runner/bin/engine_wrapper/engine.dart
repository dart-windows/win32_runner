import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../dart_project.dart';
import 'ffi.dart';

/// An instance of a Flutter engine.
class FlutterEngine {
  late final FlutterEngineAPI flutter;

  /// Handle for interacting with the C API's engine reference.
  Pointer<FlutterDesktopEngine> handle = nullptr;

  /// Messenger for communicating with the engine.
  Pointer<FlutterDesktopMessenger> messenger = nullptr;

  /// Whether the engine has been run. This will be true if Run has been called,
  /// or if RelinquishEngine has been called (since the view controller will run
  /// the engine if it hasn't already been run).
  bool hasBeenRun = false;

  /// Creates a new engine for running the given project.
  FlutterEngine(DartProject project) {
    final library = DynamicLibrary.open(
        r'c:\flutter\bin\cache\artifacts\engine\windows-x64-release\flutter_windows.dll');
    flutter = FlutterEngineAPI(library);

    // SymInitialize has already been called when Dart starts. When we invoke the
    // engine, it's called again, which leads to a Failed to init
    // NativeSymbolResolver (SymInitialize 87) error. So we clean up before we
    // call the engine.
    final hProcess = GetCurrentProcess();
    SymCleanup(hProcess);

    using((Arena arena) {
      final engineProperties = arena<FlutterDesktopEngineProperties>()
        ..ref.aot_library_path =
            project.aotLibraryPath.toNativeUtf16(allocator: arena)
        ..ref.icu_data_path =
            project.icuDataPath.toNativeUtf16(allocator: arena)
        ..ref.assets_path = project.assetsPath.toNativeUtf16(allocator: arena);
      handle = flutter.FlutterDesktopEngineCreate(engineProperties);
    });

    messenger = flutter.FlutterDesktopEngineGetMessenger(handle);
  }

  /// Starts running the engine, with an optional entry point.
  ///
  /// If provided, entry_point must be the name of a top-level function from the
  /// same Dart library that contains the app's `main()` function. If not
  /// provided, defaults to `main()`.
  bool run(String entryPoint) {
    // TODO: Implement entryPoint

    if (handle == nullptr) {
      stderr.writeln('Cannot run an engine that failed creation.');
      return false;
    }
    if (hasBeenRun) {
      stderr.writeln('Cannot run an engine more than once.');
      return false;
    }

    final runSucceeded = flutter.FlutterDesktopEngineRun(handle, nullptr) != 0;

    if (!runSucceeded) {
      stderr.writeln('Failed to start engine.');
    }

    hasBeenRun = true;
    return runSucceeded;
  }
}