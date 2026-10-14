import 'package:flutter/material.dart';

import '../theme/tds_colors.dart';
import '../theme/tds_text.dart';

/// Pestañas en forma de píldora (la activa en lima). Usa el DefaultTabController de arriba.
/// Con [desplazable] las pestañas toman su ancho y se deslizan; si no, se reparten el ancho.
class TdsTabBar extends StatelessWidget {
  const TdsTabBar({super.key, required this.tabs, this.desplazable = false});

  final List<String> tabs;
  final bool desplazable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: TdsColors.superficie, borderRadius: BorderRadius.circular(999)),
      child: TabBar(
        isScrollable: desplazable,
        tabAlignment: desplazable ? TabAlignment.start : null,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: TdsColors.acento, borderRadius: BorderRadius.circular(999)),
        labelColor: TdsColors.sobreAcento,
        unselectedLabelColor: TdsColors.textoSecundario,
        labelStyle: TdsText.label(12),
        labelPadding: desplazable ? const EdgeInsets.symmetric(horizontal: 14) : EdgeInsets.zero,
        tabs: [for (final t in tabs) Tab(height: 38, text: t)],
      ),
    );
  }
}
