import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/auth_service.dart';
import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ Could not load .env file: $e');
    debugPrint('   Make sure .env file exists in the mobile/ directory');
  }
  
  // Get Supabase credentials from .env file
  // Fallback to compile-time constants if .env is not available
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 
      const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'YOUR_SUPABASE_URL_HERE',
      );
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 
      const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE',
      );
  
  // Initialize Supabase (only if credentials are provided)
  if (supabaseUrl != 'YOUR_SUPABASE_URL_HERE' && 
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty) {
    await AuthService.initialize(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
    debugPrint('✅ Supabase initialized successfully');
  } else {
    // Show warning in debug mode
    debugPrint('⚠️ Supabase not initialized. Please set SUPABASE_URL and SUPABASE_ANON_KEY');
    debugPrint('   Create a .env file in the mobile/ directory with:');
    debugPrint('   SUPABASE_URL=your_url_here');
    debugPrint('   SUPABASE_ANON_KEY=your_key_here');
    debugPrint('   See SUPABASE_SETUP.md for detailed instructions');
  }
  
  runApp(const TileVisionApp());
}

class TileVisionApp extends StatelessWidget {
  const TileVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TileVision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Modern professional color scheme inspired by interior design apps
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C3E50), // Deep slate blue-gray
          primary: const Color(0xFF2C3E50),
          secondary: const Color(0xFFE67E22), // Warm accent (terracotta/orange)
          tertiary: const Color(0xFF95A5A6), // Neutral gray
          surface: Colors.white,
          background: const Color(0xFFF8F9FA), // Light gray background
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2C3E50),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFF2C3E50),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C3E50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
            letterSpacing: -1,
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
            letterSpacing: -0.3,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF34495E),
            letterSpacing: 0,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF7F8C8D),
            letterSpacing: 0,
          ),
        ),
      ),
      home: const AuthWrapper(),
      // Routes removed - using Navigator.push instead for screens with required parameters
    );
  }
}
