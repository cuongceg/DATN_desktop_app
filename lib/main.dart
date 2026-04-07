import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'app/education_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureDesktopWindow();

  runApp(const EducationDesktopApp());
}

Future<void> _configureDesktopWindow() async {
  if (!(Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    return;
  }

  try {
    await windowManager.ensureInitialized();
    const minWindowSize = Size(700, 760);
    const windowOptions = WindowOptions(
      minimumSize: minWindowSize,
      size: Size(1360, 860),
      center: true,
      title: 'Education Desktop UI',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } on MissingPluginException {
    // Keep app running even if desktop plugin registration is not ready.
  }
}
