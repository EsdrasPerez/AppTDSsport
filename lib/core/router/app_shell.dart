import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../features/perfil/domain/perfil.dart';
import '../../features/perfil/providers/perfil_providers.dart';
import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';
import '../widgets/tds_pill.dart';
import 'rutas.dart';

import 'package:flutter/services.dart';

const anchoEscritorio = 800.0;

/// Llave del Scaffold del shell: permite abrir el menú (Drawer) desde el AppBar de cada pantalla.
final shellScaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'shell');

bool esEscritorio(BuildContext context) => MediaQuery.sizeOf(context).width > anchoEscritorio;

/// Marco de todas las pantallas con sesión: barra lateral en escritorio (> 800 px),
/// barra de navegación inferior (BottomNavigationBar) + menú (Drawer) en móvil.
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

    final ruta = GoRouterState.of(context).uri.path;
    final ocultarBottomBar = ruta.contains('/pago');

    return Scaffold(
      key: shellScaffoldKey,
      drawer: const Drawer(width: 280, child: BarraLateral()),
      body: child,
      bottomNavigationBar: ocultarBottomBar ? null : TdsBottomNavigationBar(rutaActual: ruta),
    );
  }
}

/// Barra inferior moderna para navegación rápida con el pulgar en móviles.
class TdsBottomNavigationBar extends StatelessWidget {
  const TdsBottomNavigationBar({super.key, required this.rutaActual});

  final String rutaActual;

  int _calcularIndice(String ruta) {
    if (ruta == Rutas.inicio) return 0;
    if (ruta == Rutas.partidos || ruta.startsWith('${Rutas.partidos}/') || ruta == Rutas.calendario) return 1;
    if (ruta == Rutas.quinielas ||
        ruta.startsWith('${Rutas.quinielas}/') ||
        ruta == Rutas.quinielaNueva ||
        ruta == Rutas.quinielaUnirse) {
      return 2;
    }
    if (ruta == Rutas.misPronosticos || ruta == Rutas.rivales) return 3;
    if (ruta == Rutas.perfil || ruta.startsWith('${Rutas.perfil}/') || ruta == Rutas.suscripcion) return 4;
    return 0;
  }

  void _navegar(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0:
        context.go(Rutas.inicio);
        break;
      case 1:
        context.go(Rutas.partidos);
        break;
      case 2:
        context.go(Rutas.quinielas);
        break;
      case 3:
        context.go(Rutas.misPronosticos);
        break;
      case 4:
        context.go(Rutas.perfil);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final indiceSeleccionado = _calcularIndice(rutaActual);

    const items = [
      _BottomNavItemData(
        icono: Icons.home_rounded,
        iconoInactivo: Icons.home_outlined,
        etiqueta: 'Inicio',
      ),
      _BottomNavItemData(
        icono: Icons.sports_soccer_rounded,
        iconoInactivo: Icons.sports_soccer_outlined,
        etiqueta: 'Partidos',
      ),
      _BottomNavItemData(
        icono: Icons.emoji_events_rounded,
        iconoInactivo: Icons.emoji_events_outlined,
        etiqueta: 'Quinielas',
      ),
      _BottomNavItemData(
        icono: Icons.edit_note_rounded,
        iconoInactivo: Icons.edit_note_outlined,
        etiqueta: 'Pronósticos',
      ),
      _BottomNavItemData(
        icono: Icons.person_rounded,
        iconoInactivo: Icons.person_outline_rounded,
        etiqueta: 'Perfil',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: TdsColors.superficie,
        border: Border(
          top: BorderSide(color: TdsColors.borde.withValues(alpha: 0.5), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final activo = index == indiceSeleccionado;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _navegar(context, index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: activo ? TdsColors.acento.withValues(alpha: 0.16) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              activo ? item.icono : item.iconoInactivo,
                              color: activo ? TdsColors.acento : TdsColors.textoSecundario,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.etiqueta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TdsText.label(
                              11,
                              color: activo ? TdsColors.acento : TdsColors.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  const _BottomNavItemData({
    required this.icono,
    required this.iconoInactivo,
    required this.etiqueta,
  });

  final IconData icono;
  final IconData iconoInactivo;
  final String etiqueta;
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
  _Opcion('Calendario', Icons.calendar_month_outlined, Rutas.calendario),
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
            _Item(
              opcion: const _Opcion('Cerrar sesión', Icons.logout_rounded, Rutas.login),
              activa: false,
              color: TdsColors.error,
              onTap: () async {
                await ref.read(authRepositoryProvider).cerrarSesion();
                if (context.mounted) _ir(context, Rutas.login);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.opcion, required this.activa, required this.onTap, this.bloqueada = false, this.color});

  final _Opcion opcion;
  final bool activa;
  final bool bloqueada;
  final VoidCallback onTap;

  /// Color del ícono y texto cuando no está activa (p. ej. rojo para "Cerrar sesión").
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = activa ? TdsColors.sobreAcento : (this.color ?? TdsColors.textoSecundario);
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
