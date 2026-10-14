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
      ..invalidate(torneosActivosCountProvider)
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
    final resumen = ref.watch(resumenDashboardProvider);
    final torneos = ref.watch(torneosActivosCountProvider);

    AsyncValue<int> campo(int Function(ResumenDashboard r) f) => resumen.whenData(f);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(perfil == null ? 'Hola' : 'Hola, ${perfil.primerNombre}', style: TdsText.headline(28)),
          const SizedBox(height: 5),
          Text('Este es el resumen de tus quinielas.', style: TdsText.body(14, color: TdsColors.textoSecundario)),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildSummaryCard('TORNEOS', torneos, (_) => 'Activos', Icons.emoji_events,
                  onTap: () => context.go(Rutas.partidos)),
              _buildSummaryCard('EN VIVO', campo((r) => r.enVivo), (_) => 'En juego ahora', Icons.sensors,
                  punto: TdsColors.error, onTap: () => context.go(Rutas.partidosEnVivo())),
              _buildSummaryCard('POR PRONOSTICAR', campo((r) => r.porPronosticar), (_) => 'Pendientes',
                  Icons.assignment_late, isWarning: true, onTap: () => context.go(Rutas.misPronosticosPendientes())),
              _buildSummaryCard(
                'MIS QUINIELAS',
                campo((r) => r.activas),
                (_) {
                  final r = resumen.valueOrNull;
                  return '${r?.porTorneo ?? 0} por torneo · ${r?.porPartido ?? 0} por partido';
                },
                Icons.people_outline,
                onTap: () => context.go(Rutas.quinielas),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const ProBanner(),
          const SizedBox(height: 40),
          const MisQuinielasDashboard(),
          const SizedBox(height: 24),
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

  /// Tarjeta de resumen: esqueleto mientras carga y "—" si falla, sin romper el resto.
  Widget _buildSummaryCard(
    String title,
    AsyncValue<int> valor,
    String Function(int n) subtitle,
    IconData icon, {
    bool isWarning = false,
    Color? punto,
    VoidCallback? onTap,
  }) {
    final n = valor.valueOrNull;
    final alerta = isWarning && (n ?? 0) > 0;
    final color = alerta ? TdsColors.advertencia : TdsColors.acento;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TdsColors.superficie,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: TdsColors.sombra, blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(title, style: TdsText.label(12, color: TdsColors.textoSecundario, letterSpacing: 1.2)),
                ),
                Icon(icon, color: TdsColors.textoSecundario, size: 20),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 36,
              child: valor.isLoading && n == null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: TdsPulse(
                        child: Container(
                          width: 56,
                          height: 28,
                          decoration: BoxDecoration(
                            color: TdsColors.superficieAlta,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                  : Text(n == null ? '—' : '$n', style: TdsText.stats(32, color: color)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (punto != null && (n ?? 0) > 0) ...[TdsDot(color: punto, pulse: true), const SizedBox(width: 6)],
                if (alerta) ...[
                  const Icon(Icons.warning_amber_rounded, color: TdsColors.advertencia, size: 14),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    n == null ? ' ' : subtitle(n),
                    overflow: TextOverflow.ellipsis,
                    style: TdsText.body(12, color: alerta ? TdsColors.advertencia : TdsColors.textoSecundario),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                texto: 'Aún no tienes actividad. Únete a una quiniela para empezar.',
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
