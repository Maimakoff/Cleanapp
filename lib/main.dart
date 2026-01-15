import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/auth_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/date_formatter.dart';
import 'core/utils/logger.dart';
import 'core/widgets/error_fallback_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем локализацию для форматирования дат (русский язык)
  try {
    await initializeDateFormatting('ru', null);
    // Устанавливаем флаг инициализации в DateFormatter
    DateFormatter.setInitialized(true);
    debugPrint('✅ Локализация для форматирования дат инициализирована');
  } catch (e) {
    debugPrint('⚠️ Ошибка инициализации локализации: $e');
    debugPrint('   Форматирование дат будет работать без локализации');
    DateFormatter.setInitialized(false);
  }

  // Load environment variables
  bool supabaseInitialized = false;
  
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('📄 .env file loaded successfully');
    
    // Initialize Supabase only if env variables are available
    final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
    
    if (supabaseUrl != null && supabaseKey != null && 
        supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
      debugPrint('🔑 Found Supabase credentials in .env');
      debugPrint('   URL: ${supabaseUrl.substring(0, supabaseUrl.length > 30 ? 30 : supabaseUrl.length)}...');
      debugPrint('   Key length: ${supabaseKey.length}');
      
      try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
        supabaseInitialized = true;
        debugPrint('✅ Supabase initialized successfully!');
      } catch (e) {
        debugPrint('❌ ERROR initializing Supabase: $e');
        debugPrint('   This usually means:');
        debugPrint('   1. Invalid Supabase URL or Key');
        debugPrint('   2. Network connection issue');
        debugPrint('   3. Supabase project is paused or deleted');
        // Не прерываем выполнение, но Supabase не будет работать
      }
    } else {
      debugPrint('⚠️ Supabase credentials not found or empty in .env file');
      debugPrint('   SUPABASE_URL: ${supabaseUrl ?? "null"}');
      debugPrint('   SUPABASE_ANON_KEY: ${supabaseKey != null ? "exists (${supabaseKey.length} chars)" : "null"}');
      debugPrint('   Make sure .env file contains:');
      debugPrint('   SUPABASE_URL=https://your-project.supabase.co');
      debugPrint('   SUPABASE_ANON_KEY=your-anon-key-here');
    }
  } catch (e) {
    // If .env file doesn't exist or can't be loaded
    debugPrint('⚠️ ERROR loading .env file: $e');
    debugPrint('   Make sure .env file exists in the project root directory');
    debugPrint('   File path should be: ${Uri.base.path}.env');
  }
  
  if (!supabaseInitialized) {
    debugPrint('');
    debugPrint('⚠️ ⚠️ ⚠️ WARNING: Supabase is NOT initialized ⚠️ ⚠️ ⚠️');
    debugPrint('   Authentication and database features will NOT work!');
    debugPrint('   Please check the .env file and restart the app (not hot reload)');
    debugPrint('');
  }

  // Global error handler for Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log error using centralized logger
    AppLogger.logError(
      details.exception,
      stackTrace: details.stack,
      context: 'Flutter Framework',
      additionalInfo: {
        'library': details.library,
        'information': details.informationCollector?.call().join('\n'),
      },
    );

    // In debug mode, show the error overlay
    // In production, errors are handled by ErrorWidget.builder
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

  // Global error handler for uncaught async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    // Log error using centralized logger
    AppLogger.logError(
      error,
      stackTrace: stack,
      context: 'Async Error',
    );

    // Return true to prevent app crash
    return true;
  };

  // Custom error widget builder to prevent red screen of death
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return ErrorFallbackWidget(
      errorDetails: details,
      customMessage: 'Произошла ошибка при отображении интерфейса.',
    );
  };

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(
        title: 'Cleanapp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          // Global error boundary for UI
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
