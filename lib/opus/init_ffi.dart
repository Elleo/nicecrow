import 'dart:ffi';
import 'dart:io' show Platform;

Future<void> initFfi() async {}

DynamicLibrary openOpus() {
  DynamicLibrary lib;
  if (Platform.isWindows) {
    bool x64 = Platform.version.contains('x64');
    if (x64) {
      lib =
          new DynamicLibrary.open('libopus_x64.dll');
    } else {
      lib = new DynamicLibrary.open('libopus_x86.dll');
    }
  } else if (Platform.isLinux) {
    lib = new DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libopus.so');
  } else {
    throw new UnsupportedError('Unsupported platform for opus');
  }
  return lib;
}
