import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // Font yang lebih modern
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'package:provider/provider.dart';
import 'services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => DatabaseService()),
      ],
      child: MaterialApp(
        title: 'List.InAja',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: _getHomeScreenBasedOnAuth(),
      ),
    );
  }

  Widget _getHomeScreenBasedOnAuth() {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder<User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              return const HomeScreen();
            }
            return const AuthScreen();
          },
        );
      },
    );
  }
  
  ThemeData _buildTheme(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    final Color primaryColor = isLight ? const Color(0xFF6A5AE0) : const Color(0xFF8B7FF1);
    final Color scaffoldBgColor = isLight ? const Color(0xFFF8F7FB) : const Color(0xFF121212);
    final Color cardColor = isLight ? Colors.white : const Color(0xFF1E1E1E);
    final Color textColor = isLight ? const Color(0xFF2C2C2C) : Colors.white70;

    final baseTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBgColor,
      textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: brightness).textTheme).apply(bodyColor: textColor),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: isLight ? const Color(0xFF50E3C2) : const Color(0xFF50E3C2),
        background: scaffoldBgColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.inter(
          color: isLight ? Colors.black87 : Colors.white, 
          fontSize: 20, 
          fontWeight: FontWeight.w600
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        floatingLabelStyle: TextStyle(color: primaryColor),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isLight ? BorderSide(color: Colors.grey.shade200) : BorderSide(color: Colors.grey.shade800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey.shade500,
        indicatorColor: primaryColor,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
    );
  }
}