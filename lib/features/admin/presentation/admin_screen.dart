import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../perfil/providers/perfil_providers.dart';
import 'widgets/admin_equipos.dart';
import 'widgets/admin_partidos.dart';
import 'widgets/admin_torneos.dart';

enum SeccionAdmin { torneos, equipos, partidos }

/// Administración (/admin). Solo para perfiles con es_admin; el router y esta pantalla lo validan,
/// y la RLS lo exige en la base.
class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key, this.seccion = SeccionAdmin.torneos});

  final SeccionAdmin seccion;

  static String _ruta(SeccionAdmin s) => switch (s) {
        SeccionAdmin.torneos => Rutas.adminTorneos,
        SeccionAdmin.equipos => Rutas.adminEquipos,
        SeccionAdmin.partidos => Rutas.adminPartidos,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilActualProvider);

    return Scaffold(
      appBar: const TdsAppBar(titulo: 'ADMINISTRACIÓN'),
      body: AsyncValueView(
        value: perfil,
        onReintentar: () => ref.invalidate(perfilActualProvider),
        data: (p) {
          if (!(p?.esAdmin ?? false)) {
            return VacioView(
              icono: Icons.lock_outline,
              texto: 'Solo los administradores pueden entrar aquí.',
              acciones: [
                TdsPillButton(icon: Icons.home_outlined, label: 'Ir a Inicio', onTap: () => context.go(Rutas.inicio)),
              ],
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: TdsFilterChipsRow(
                  chips: [
                    for (final (s, texto, icono) in const [
                      (SeccionAdmin.torneos, 'Torneos', Icons.emoji_events_outlined),
                      (SeccionAdmin.equipos, 'Equipos', Icons.shield_outlined),
                      (SeccionAdmin.partidos, 'Partidos', Icons.sports_soccer),
                    ])
                      TdsFilterChip(
                        texto: texto,
                        icono: icono,
                        activo: seccion == s,
                        onTap: () => context.go(_ruta(s)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: switch (seccion) {
                  SeccionAdmin.torneos => const AdminTorneos(),
                  SeccionAdmin.equipos => const AdminEquipos(),
                  SeccionAdmin.partidos => const AdminPartidos(),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
