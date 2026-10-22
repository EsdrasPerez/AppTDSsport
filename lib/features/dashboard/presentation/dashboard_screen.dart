import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../../quinielas/presentation/widgets/mis_quinielas_dashboard.dart';
import '../../quinielas/providers/quinielas_providers.dart';
import '../../suscripcion/presentation/widgets/pro_banner.dart';
import '../../suscripcion/providers/suscripcion_providers.dart';

/// Panel principal (/inicio). La barra lateral la pone el shell (AppShell).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _recargar(WidgetRef ref) async {
    ref
      ..invalidate(perfilActualProvider)
      ..invalidate(misPagosProvider)
      ..invalidate(misQuinielasProvider);
    await ref.read(misQuinielasProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: TdsAppBar(titulo: 'TDS SPORT', onRefrescar: () => _recargar(ref)),
      body: RefreshIndicator(
        onRefresh: () => _recargar(ref),
        child: _buildMainContent(context, ref),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilActualProvider).valueOrNull;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(perfil == null ? 'Hola' : 'Hola, ${perfil.primerNombre}', style: TdsText.headline(28)),
          const SizedBox(height: 5),
          Text('Este es el resumen de tus quinielas.', style: TdsText.body(14, color: TdsColors.textoSecundario)),
          const SizedBox(height: 25),
          _buildBannerQuinielas(context),
          const SizedBox(height: 30),
          const MisQuinielasDashboard(),
          const SizedBox(height: 24),
          const ProBanner(),
        ],
      ),
    );
  }

  /// Banner de acceso directo a Quinielas: crear una nueva (unirse con código está en "Quinielas de amigos").
  Widget _buildBannerQuinielas(BuildContext context) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('¡Módulo de Quinielas Deportivo!', style: TdsText.headline(18)),
        const SizedBox(height: 6),
        Text(
          'Crea una nueva quiniela con código de invitación único o únete a una existente con tu código.',
          style: TdsText.body(13, color: TdsColors.textoSecundario),
        ),
      ],
    );
    // Mismo estilo que "Unirse con código" de Quinielas de amigos
    final boton = TdsPillButton(
      icon: Icons.add_circle_outline,
      label: 'Crear quiniela',
      primary: true,
      onTap: () => context.push(Rutas.quinielaNueva),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TdsColors.superficieAlta, TdsColors.superficie],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TdsColors.acento.withValues(alpha: 0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 560
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [titulo, const SizedBox(height: 16), Center(child: boton)],
              )
            : Row(children: [Expanded(child: titulo), const SizedBox(width: 16), boton]),
      ),
    );
  }
}
