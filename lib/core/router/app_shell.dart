import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/perfil/domain/perfil.dart';
import '../../features/perfil/providers/perfil_providers.dart';
import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';
import '../widgets/tds_pill.dart';
import 'rutas.dart';

const anchoEscritorio = 800.0;

/// Llave del Scaffold del shell: permite abrir el menú (Drawer) desde el AppBar de cada pantalla.
final shellScaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'shell');

bool esEscritorio(BuildContext context) => MediaQuery.sizeOf(context).width > anchoEscritorio;

/// Marco de todas las pantallas con sesión: barra lateral en escritorio (> 800 px),
/// menú (Drawer) en móvil.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (esEscritorio(context)) {
      return Scaffold(
        key: shellScaffoldKey,
        body: Row(children: [const BarraLateral(), Expanded(child: child)]),
      );
    }
    return Scaffold(
      key: shellScaffoldKey,
      drawer: const Drawer(width: 280, child: BarraLateral()),
      body: child,
    );
  }
}

class _Opcion {
  const _Opcion(this.etiqueta, this.icono, this.ruta, {this.soloPro = false});

  final String etiqueta;
  final IconData icono;
  final String ruta;
  final bool soloPro;
}

const _opciones = [
  _Opcion('Panel principal', Icons.dashboard_outlined, Rutas.inicio),
  _Opcion('Partidos', Icons.sports_soccer, Rutas.partidos),
  _Opcion('Mis quinielas', Icons.emoji_events_outlined, Rutas.quinielas),
  _Opcion('Mis pronósticos', Icons.edit_note, Rutas.misPronosticos),
  _Opcion('Pronósticos de rivales', Icons.visibility_outlined, Rutas.rivales, soloPro: true),
  _Opcion('Suscripción', Icons.star_border, Rutas.suscripcion),
];

/// Menú principal. La opción activa sale de la ruta actual.
class BarraLateral extends ConsumerWidget {
  const BarraLateral({super.key});

  void _ir(BuildContext context, String ruta, {bool apilar = false}) {
    final scaffold = shellScaffoldKey.currentState;
    if (scaffold?.isDrawerOpen ?? false) scaffold!.closeDrawer();
    apilar ? context.push(ruta) : context.go(ruta);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilActualProvider).valueOrNull;
    final ruta = GoRouterState.of(context).uri.path;
    final plan = perfil?.planVigente ?? PlanUsuario.gratis;

    bool activa(String r) => r == Rutas.inicio ? ruta == r : (ruta == r || ruta.startsWith('$r/'));

    return Container(
      width: 250,
      color: TdsColors.superficie,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.sports_soccer, color: TdsColors.acento, size: 28),
                  const SizedBox(width: 10),
                  Text('TDS Sport', style: TdsText.headline(20)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Avatar + nombre + plan → Editar mi perfil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Material(
                color: activa(Rutas.perfil) ? TdsColors.superficieAlta : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _ir(context, Rutas.perfil, apilar: true),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: TdsColors.acento,
                          child: Text(
                            (perfil?.nombre.isNotEmpty ?? false) ? perfil!.nombre[0].toUpperCase() : '?',
                            style: TdsText.label(16, color: TdsColors.sobreAcento),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(perfil?.nombre ?? 'Mi perfil',
                                        overflow: TextOverflow.ellipsis, style: TdsText.label(14)),
                                  ),
                                  const SizedBox(width: 6),
                                  _InsigniaPlan(plan: plan),
                                ],
                              ),
                              Text('Editar mi perfil', style: TdsText.body(12, color: TdsColors.textoSecundario)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            for (final o in _opciones)
              _Item(
                opcion: o,
                activa: activa(o.ruta),
                bloqueada: o.soloPro && plan == PlanUsuario.gratis,
                onTap: () => _ir(context, o.ruta),
              ),
            if (perfil?.esAdmin ?? false)
              _Item(
                opcion: const _Opcion('Administración', Icons.admin_panel_settings_outlined, Rutas.admin),
                activa: activa(Rutas.admin),
                onTap: () => _ir(context, Rutas.admin),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.opcion, required this.activa, required this.onTap, this.bloqueada = false});

  final _Opcion opcion;
  final bool activa;
  final bool bloqueada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activa ? TdsColors.sobreAcento : TdsColors.textoSecundario;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: activa ? TdsColors.acento : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Row(
              children: [
                Icon(opcion.icono, color: color, size: 20),
                const SizedBox(width: 14),
                Expanded(child: Text(opcion.etiqueta, style: TdsText.label(14, color: color))),
                if (opcion.soloPro)
                  TdsPill(
                    color: activa ? TdsColors.sobreAcento : TdsColors.superficieAlta,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (bloqueada) ...[
                          const Icon(Icons.lock, size: 10, color: TdsColors.acento),
                          const SizedBox(width: 3),
                        ],
                        Text('PRO', style: TdsText.label(9, color: TdsColors.acento)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsigniaPlan extends StatelessWidget {
  const _InsigniaPlan({required this.plan});

  final PlanUsuario plan;

  @override
  Widget build(BuildContext context) {
    final destacado = plan != PlanUsuario.gratis;
    return TdsPill(
      color: destacado ? TdsColors.acento : TdsColors.superficieAlta,
      child: Text(plan.etiqueta.toUpperCase(),
          style: TdsText.label(9, color: destacado ? TdsColors.sobreAcento : TdsColors.textoSecundario)),
    );
  }
}
