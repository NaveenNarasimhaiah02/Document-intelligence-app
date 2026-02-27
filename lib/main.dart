import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/ac.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final storage = StorageService();
  try {
    await storage.init();
  } catch (e) {
    debugPrint('Init Error: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(DocumentClassifierApp(storage: storage));
}

class DocumentClassifierApp extends StatelessWidget {
  final StorageService storage;
  const DocumentClassifierApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = storage.settingsBox.get('isLoggedIn', defaultValue: false);

    return MaterialApp(
      title: 'SmartScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AC.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: AC.header2),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AC.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AC.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AC.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AC.accent, width: 2)),
          hintStyle: const TextStyle(color: AC.textS, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: isLoggedIn ? HomeScreen(storage: storage) : LoginScreen(storage: storage),
    );
  }
}
