import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/rutas.dart';
import '../../../core/theme/tds_colors.dart';
import '../../../core/theme/tds_text.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/tds_ui.dart';
import '../../perfil/providers/perfil_providers.dart';
import '../../quinielas/presentation/widgets/mis_quinielas_dashboard.dart';
import '../../quinielas/providers/quinielas_providers.dart';
import '../../suscripcion/presentation/widgets/pro_banner.dart';
import '../../suscripcion/providers/suscripcion_providers.dart';
import '../domain/evento_actividad.dart';
import '../providers/dashboard_providers.dart';

/// Panel principal (/inicio). La barra lateral la pone el shell (AppShell).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _recargar(WidgetRef ref) async {
    ref
      ..invalidate(perfilActualProvider)
      ..invalidate(misPagosProvider)
      ..invalidate(actividadRecienteProvider)
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
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Actividad Reciente', style: TdsText.headline(20)),
              TextButton(
                onPressed: () => context.go(Rutas.misPronosticos),
                child: Text('Ver todo ➔', style: TdsText.label(14, color: TdsColors.acento)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActivityTable(context, ref),
        ],
      ),
    );
  }

  /// Banner de acceso directo a Quinielas: crear una nueva.
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
    final botones = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: TdsColors.acento,
            foregroundColor: TdsColors.sobreAcento,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Crear Quiniela'),
          onPressed: () => context.push(Rutas.quinielaNueva),
        ),
      ],
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
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titulo, const SizedBox(height: 16), botones])
            : Row(children: [Expanded(child: titulo), const SizedBox(width: 16), botones]),
      ),
    );
  }

  Widget _buildActivityTable(BuildContext context, WidgetRef ref) {
    final actividad = ref.watch(actividadRecienteProvider);
    final encabezado = TdsText.label(12, color: TdsColors.textoSecundario);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: TdsColors.superficie, borderRadius: BorderRadius.circular(24)),
      child: actividad.when(
        skipLoadingOnRefresh: true,
        loading: () => const Padding(padding: EdgeInsets.all(24), child: CargandoView()),
        error: (e, _) => ErrorView.desde(e, onReintentar: () => ref.invalidate(actividadRecienteProvider)),
        data: (eventos) => eventos.isEmpty
            ? VacioView(
                icono: Icons.history,
                texto: 'Únete a la quiniela de un amigo.',
                compacto: true,
                acciones: [
                  TdsPillButton(
                    icon: Icons.group_add_outlined,
                    label: 'Unirse con código',
                    primary: true,
                    onTap: () => context.push(Rutas.quinielaUnirse),
                  ),
                ],
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text('EVENTO', style: encabezado)),
                        Expanded(flex: 2, child: Text('TIPO', style: encabezado)),
                        Expanded(flex: 2, child: Text('ESTADO', style: encabezado)),
                        Expanded(child: Text('FECHA', style: encabezado, textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  for (final e in eventos) _buildActivityRow(context, e),
                ],
              ),
      ),
    );
  }

  static const _iconos = {
    TipoEvento.pronostico: Icons.edit_note,
    TipoEvento.resultado: Icons.scoreboard_outlined,
    TipoEvento.quiniela: Icons.group_add_outlined,
    TipoEvento.quinielaFinalizada: Icons.emoji_events_outlined,
    TipoEvento.suscripcion: Icons.workspace_premium,
  };

  Widget _buildActivityRow(BuildContext context, EventoActividad e) {
    final statusColor = e.positivo ? TdsColors.exito : TdsColors.textoSecundario;

    return InkWell(
      onTap: e.quinielaId == null ? null : () => context.push(Rutas.quiniela(e.quinielaId!)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: TdsColors.borde, width: 1))),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_iconos[e.tipo], color: statusColor, size: 16),
                  ),
                  const SizedBox(width: 15),
                  Expanded(child: Text(e.titulo, overflow: TextOverflow.ellipsis, style: TdsText.label(13))),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(e.tipoTexto,
                  overflow: TextOverflow.ellipsis, style: TdsText.body(13, color: TdsColors.textoSecundario)),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(e.estado, style: TdsText.label(12, color: statusColor)),
                ),
              ),
            ),
            Expanded(
              child: Text(Formatos.relativo(e.fecha),
                  textAlign: TextAlign.right, style: TdsText.body(12, color: TdsColors.textoSecundario)),
            ),
          ],
        ),
      ),
    );
  }
}
