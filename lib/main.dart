import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'controllers/drive_controller.dart';
import 'controllers/music_controller.dart';
import 'controllers/settings_controller.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const RoadAiApp());
}

class RoadAiApp extends StatelessWidget {
  const RoadAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => MusicController()),
        ChangeNotifierProxyProvider2<SettingsController, MusicController,
            DriveController>(
          create: (ctx) => DriveController(
            ctx.read<SettingsController>(),
            ctx.read<MusicController>(),
          ),
          update: (_, _, _, drive) => drive!,
        ),
      ],
      child: MaterialApp(
        title: 'RoadAI — Sakin Sürüş Asistanı',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        locale: const Locale('tr'),
        supportedLocales: const [Locale('tr'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
