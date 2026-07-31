import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/database/database_init.dart';
import 'package:al_daa_wal_dawaa/core/router/app_router.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:al_daa_wal_dawaa/data/remote/update_service.dart';
import 'package:al_daa_wal_dawaa/data/services/app_audio_handler.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,  // Android
      statusBarBrightness: Brightness.dark,        // iOS
    ),
  );

  await initDatabaseFactory();
  await DatabaseHelper.instance.database;

  final audioHandler = await AudioService.init<AppAudioHandler>(
    builder: AppAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: AppConstants.androidNotificationChannelId,
      androidNotificationChannelName:
          AppConstants.androidNotificationChannelName,
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const AlDaaWalDawaaApp(),
    ),
  );
}

class AlDaaWalDawaaApp extends ConsumerStatefulWidget {
  const AlDaaWalDawaaApp({super.key});

  @override
  ConsumerState<AlDaaWalDawaaApp> createState() => _AlDaaWalDawaaAppState();
}

class _AlDaaWalDawaaAppState extends ConsumerState<AlDaaWalDawaaApp> {
  @override
  void initState() {
    super.initState();
    // بعد ثانيتين من بدء التطبيق نتحقق من وجود تحديث
    Future.delayed(const Duration(seconds: 2), _checkForUpdate);
  }

  Future<void> _checkForUpdate() async {
    final info = await UpdateService.checkForUpdate();
    if (info == null) return;

    // نحصل على السياق من المتصفح العام
    final ctx = AppRouter.navigatorKey.currentContext;
    if (ctx == null || !mounted || !ctx.mounted) return;

    _showUpdateDialog(ctx, info);
  }

  void _showUpdateDialog(BuildContext ctx, UpdateInfo info) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('يوجد تحديث جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار الجديد: ${info.version}'),
            if (info.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(info.notes),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('لاحقاً'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (info.apkUrl.isNotEmpty) {
                final uri = Uri.parse(info.apkUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: const Text('تحديث الآن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
    );
  }
}
