import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/registro_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/quinielas/presentation/quinielas_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Cargar las variables de entorno si existen
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  // 2. Inicializar Supabase usando las variables seguras con fallback oficial
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://qtxxcundordklfclweuk.supabase.co';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF0eHhjdW5kb3Jka2xmY2x3ZXVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAxNzM5NzcsImV4cCI6MjEwNTc0OTk3N30.kD-ABFS93-0ZwNNjhu-iVOtWNSea-ijkFGwIN_dgWdg';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const TDSPORTApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegistroScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/quinielas',
      builder: (context, state) => const QuinielasScreen(),
    ),
    GoRoute(
      path: '/quinielas/crear',
      builder: (context, state) => const QuinielasScreen(tabInicial: 1),
    ),
    GoRoute(
      path: '/quinielas/unirse',
      builder: (context, state) => const QuinielasScreen(tabInicial: 2),
    ),
  ],
);

class TDSPORTApp extends StatelessWidget {
  const TDSPORTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'App TDSPORT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          surface: Color(0xFF1E293B),
        ),
      ),
      routerConfig: _router,
    );
  }
}
