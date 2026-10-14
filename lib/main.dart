import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:tdsport_app/features/auth/presentation/registro_screen.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/auth/presentation/perfil_screen.dart';

// Pantallas, rutas y tema agregados
import 'core/router/app_shell.dart';
import 'core/router/hoja_page.dart';
import 'core/router/proteccion_rutas.dart';
import 'core/router/rutas.dart';
import 'core/theme/tds_theme.dart';
import 'features/admin/presentation/admin_screen.dart';
import 'features/auth/presentation/recuperar_screen.dart';
import 'features/partidos/presentation/partidos_screen.dart';
import 'features/perfil/presentation/historial_screen.dart';
import 'features/quinielas/presentation/crear_quiniela_sheet.dart';
import 'features/quinielas/presentation/mis_pronosticos_screen.dart';
import 'features/quinielas/presentation/mis_quinielas_screen.dart';
import 'features/quinielas/presentation/participante_screen.dart';
import 'features/quinielas/presentation/quiniela_detalle_screen.dart';
import 'features/quinielas/presentation/quinielas_screen.dart';
import 'features/quinielas/presentation/rivales_screen.dart';
import 'features/quinielas/presentation/unirse_quiniela_sheet.dart';
import 'features/suscripcion/domain/pasarela_pago.dart';
import 'features/suscripcion/presentation/pago/pago_resultado_screen.dart';
import 'features/suscripcion/presentation/pago/pago_screen.dart';
import 'features/suscripcion/presentation/suscripcion_screen.dart';

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
    // ignore: deprecated_member_use
    anonKey: supabaseAnonKey,
  );

  // ProviderScope: necesario para los providers (Riverpod)
  runApp(const ProviderScope(child: TDSPORTApp()));
}

final _raizKey = GlobalKey<NavigatorState>(debugLabel: 'raiz');

final GoRouter _router = GoRouter(
  navigatorKey: _raizKey,
  initialLocation: '/login',
  // Si hay sesión no muestra el login; si no hay sesión no deja abrir pantallas privadas
  refreshListenable: RefrescoSesion(),
  redirect: redirectSesion,
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/registro',
      builder: (context, state) => const RegistroScreen(),
    ),
    GoRoute(path: Rutas.recuperar, builder: (context, state) => const RecuperarScreen()),

    // Rutas anteriores (compatibilidad con enlaces viejos)
    GoRoute(path: '/', redirect: (_, _) => Rutas.inicio),
    GoRoute(path: '/dashboard', redirect: (_, _) => Rutas.inicio),
    GoRoute(path: '/profile', redirect: (_, _) => Rutas.perfil),

    // Todas las pantallas con sesión, dentro del shell con la barra lateral
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: Rutas.inicio,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: Rutas.perfil,
          builder: (context, state) => const PerfilScreen(),
          routes: [
            GoRoute(path: 'historial', builder: (context, state) => const HistorialScreen()),
          ],
        ),
        GoRoute(
          path: Rutas.partidos,
          builder: (context, state) => PartidosScreen(tabInicial: state.uri.queryParameters['tab']),
        ),
        GoRoute(
          path: Rutas.misPronosticos,
          builder: (context, state) => MisPronosticosScreen(filtroInicial: state.uri.queryParameters['filtro']),
        ),
        GoRoute(
          path: Rutas.rivales,
          builder: (context, state) => RivalesScreen(
            quinielaId: state.uri.queryParameters['quiniela'],
            partidoId: state.uri.queryParameters['partido'],
          ),
        ),
        GoRoute(
          path: Rutas.suscripcion,
          builder: (context, state) => const SuscripcionScreen(),
          routes: [
            GoRoute(
              path: 'pago',
              builder: (context, state) => PagoScreen(plan: state.uri.queryParameters['plan'] ?? 'pro'),
              routes: [
                GoRoute(
                  path: 'resultado',
                  builder: (context, state) => PagoResultadoScreen(resultado: state.extra as ResultadoPago?),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: Rutas.quinielas,
          builder: (context, state) => const MisQuinielasScreen(),
          routes: [
            // Antes de ':id' para que no se confundan con un id
            GoRoute(
              path: 'nueva',
              parentNavigatorKey: _raizKey,
              pageBuilder: (context, state) => HojaInferiorPage(
                key: state.pageKey,
                child: CrearQuinielaSheet(
                  tipo: state.uri.queryParameters['tipo'],
                  torneoId: state.uri.queryParameters['torneo'],
                  partidoId: state.uri.queryParameters['partido'],
                ),
              ),
            ),
            GoRoute(
              path: 'unirse',
              parentNavigatorKey: _raizKey,
              pageBuilder: (context, state) => HojaInferiorPage(
                key: state.pageKey,
                child: UnirseQuinielaSheet(codigoInicial: state.uri.queryParameters['codigo']),
              ),
            ),
            // Módulo de quinielas (crear / unirse con pestañas)
            GoRoute(
              path: 'crear',
              builder: (context, state) => const QuinielasScreen(tabInicial: 1),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => QuinielaDetalleScreen(
                quinielaId: state.pathParameters['id']!,
                soloLectura: state.uri.queryParameters['lectura'] == '1',
              ),
              routes: [
                GoRoute(
                  path: 'participante/:usuarioId',
                  builder: (context, state) => ParticipanteScreen(
                    quinielaId: state.pathParameters['id']!,
                    usuarioId: state.pathParameters['usuarioId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: Rutas.admin,
          builder: (context, state) => const AdminScreen(),
          routes: [
            GoRoute(path: 'torneos', builder: (context, state) => const AdminScreen(seccion: SeccionAdmin.torneos)),
            GoRoute(path: 'equipos', builder: (context, state) => const AdminScreen(seccion: SeccionAdmin.equipos)),
            GoRoute(path: 'partidos', builder: (context, state) => const AdminScreen(seccion: SeccionAdmin.partidos)),
          ],
        ),
      ],
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
      // Tema único con la paleta del login
      theme: TdsTheme.oscuro,
      routerConfig: _router,
    );
  }
}
