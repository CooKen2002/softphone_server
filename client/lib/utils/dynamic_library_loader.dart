import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class DynamicLibraryLoader {
  static DynamicLibrary dylib = loadLibrary();
  static void isolateEntryPoint(String args) {
    final start = dylib.lookupFunction<Void Function(), void Function()>(
      'libBaresip_init',
    );
    start();
  }

  static DynamicLibrary loadLibrary() {
    String dllPath = "";
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    if (kReleaseMode) {
      dllPath = path.join(exeDir, 'data', 'flutter_assets', 'assets', 'dll');
    } else {
      dllPath = path.join(Directory.current.path, 'assets', 'dll');
    }
    // dllPath = path.join(exeDir, 'data', 'flutter_assets', 'assets', 'dll');
    String libsndfileDllPath = path.join(dllPath, "sndfile.dll");
    String baresipDllPathth = path.join(dllPath, "baresip-window.dll");
    DynamicLibrary.open(libsndfileDllPath);
    DynamicLibrary lib = DynamicLibrary.open(baresipDllPathth);
    return lib;
  }
}
