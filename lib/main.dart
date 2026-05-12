import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app/education_app.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/presentation/controllers/auth_notifier.dart';
import 'features/classroom/classroom_providers.dart';
import 'features/classroom/presentation/controllers/classroom_notifier.dart';
import 'services/api_client.dart';
import 'services/auth_storage.dart';
import 'features/session/data/session_api.dart';
import 'features/session/data/session_repository.dart';
import 'features/session/providers/session_provider.dart';
import 'features/session/services/session_service.dart';
import 'features/stt/services/stt_service.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  _suppressKnownWebRtcErrors();
  await _configureDesktopWindow();

  // --- STT model pre-load (runs before UI appears) ---
  final sttService = SttService();
  try {
    await sttService.initialize();
  } catch (e) {
    // initError is stored on sttService; screen will surface it
    debugPrint('STT init failed: $e');
  }

  // --- Dependency wiring ---
  const secureStorage = FlutterSecureStorage();

  // Legacy AuthStorage kept alive so ApiClient interceptor can still read
  // the token written by AuthLocalDataSourceImpl (same storage key).
  final authStorage = AuthStorage(secureStorage);
  final apiClient = ApiClient(authStorage: authStorage);

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(apiClient.dio),
    localDataSource: AuthLocalDataSourceImpl(secureStorage),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>(
          create: (_) => AuthNotifier(
            signInUseCase: SignInUseCase(authRepository),
            signOutUseCase: SignOutUseCase(authRepository),
            getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
          ),
        ),
        ChangeNotifierProvider<ClassroomNotifier>(
          create: (_) => ClassroomProviders.createNotifier(apiClient.dio),
        ),
        ChangeNotifierProvider<SessionProvider>(
          create: (_) => SessionProvider(
            SessionService(SessionRepository(SessionApi(apiClient.dio))),
          ),
        ),
        Provider<SttService>.value(value: sttService),
      ],
      child: EducationDesktopApp(
        authStorage: authStorage,
        apiClient: apiClient,
      ),
    ),
  );
}

// Suppresses PlatformException("No active stream to cancel") thrown by the
// flutter_webrtc EventChannel when the native RTCPeerConnection is closed
// before the Dart-side subscription cancel message reaches the platform.
void _suppressKnownWebRtcErrors() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final exception = details.exception;
    if (exception is PlatformException &&
        (exception.message?.contains('No active stream to cancel') ?? false)) {
      return;
    }
    if (originalOnError != null) {
      originalOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };
}

Future<void> _configureDesktopWindow() async {
  const _flavor = String.fromEnvironment('APP_FLAVOR');
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
      title: _flavor == ''
          ? 'Education Desktop UI'
          : 'Education Desktop UI $_flavor',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } on MissingPluginException {
    // Keep app running even if desktop plugin registration is not ready.
  }
}
