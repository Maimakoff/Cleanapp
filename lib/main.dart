import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'core/routing/app_router.dart';
import 'theme/app_theme.dart';
import 'core/utils/date_formatter.dart';

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

  // Устанавливаем глобальный обработчик ошибок Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Обработчик ошибок для асинхронных операций
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🚨 Async Error: $error');
    debugPrint('Stack trace: $stack');
    return true; // Предотвращаем краш приложения
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp.router(
        title: 'Cleanapp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          // Глобальная обработка ошибок UI
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
