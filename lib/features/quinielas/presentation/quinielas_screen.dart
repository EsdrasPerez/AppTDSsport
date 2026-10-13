import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/quinielas_repository.dart';
import '../models/quiniela_model.dart';
import 'crear_quiniela_view.dart';
import 'unirse_quiniela_view.dart';

class QuinielasScreen extends StatefulWidget {
  final int tabInicial;

  const QuinielasScreen({
    Key? key,
    this.tabInicial = 0,
  }) : super(key: key);

  @override
  State<QuinielasScreen> createState() => _QuinielasScreenState();
}

class _QuinielasScreenState extends State<QuinielasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _quinielasRepo = QuinielasRepository();

  List<QuinielaModel> _misQuinielas = [];
  bool _cargandoQuinielas = true;
  String? _errorQuinielas;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.tabInicial);
    _cargarMisQuinielas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarMisQuinielas() async {
    setState(() {
      _cargandoQuinielas = true;
      _errorQuinielas = null;
    });

    try {
      final quinielas = await _quinielasRepo.getMisQuinielas();
      setState(() {
        _misQuinielas = quinielas;
        _cargandoQuinielas = false;
      });
    } catch (e) {
      setState(() {
        _errorQuinielas = 'No se pudieron cargar tus quinielas. Toca para reintentar.';
        _cargandoQuinielas = false;
      });
    }
  }

  void _irAMisQuinielas() {
    _cargarMisQuinielas();
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // Barra superior con pestañas del módulo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: const Color(0xFF3B82F6),
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.sports_soccer, size: 20),
                        text: 'Mis Quinielas',
                      ),
                      Tab(
                        icon: Icon(Icons.add_circle_outline, size: 20),
                        text: 'Crear Quiniela',
                      ),
                      Tab(
                        icon: Icon(Icons.group_add, size: 20),
                        text: 'Unirse por Código',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Recargar',
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: _cargarMisQuinielas,
                ),
              ],
            ),
          ),

          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMisQuinielasTab(),
                CrearQuinielaView(onQuinielaCreada: _irAMisQuinielas),
                UnirseQuinielaView(onUnido: _irAMisQuinielas),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisQuinielasTab() {
    if (_cargandoQuinielas) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF3B82F6)),
            SizedBox(height: 16),
            Text(
              'Cargando tus quinielas...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorQuinielas != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(
              _errorQuinielas!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarMisQuinielas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            ),
          ],
        ),
      );
    }

    if (_misQuinielas.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events_outlined, color: Color(0xFF60A5FA), size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aún no perteneces a ninguna quiniela',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea tu propia quiniela para competir con amigos o únete con un código de invitación.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Crear Quiniela'),
                    onPressed: () => _tabController.animateTo(1),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.group_add, size: 20, color: Color(0xFF34D399)),
                    label: const Text('Unirme con Código'),
                    onPressed: () => _tabController.animateTo(2),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarMisQuinielas,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _misQuinielas.length,
        itemBuilder: (context, index) {
          final quiniela = _misQuinielas[index];
          return _buildQuinielaCard(quiniela);
        },
      ),
    );
  }

  Widget _buildQuinielaCard(QuinielaModel q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_soccer, color: Color(0xFF60A5FA), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      q.torneoNombre ?? 'Torneo Oficial',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${q.puntosUsuario} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // Código de invitación para compartir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Código: ',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                    ),
                    child: Text(
                      q.codigoAcceso,
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copiar código',
                    icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: q.codigoAcceso));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Código "${q.codigoAcceso}" copiado'),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, color: Colors.white54, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Límite: ${q.limiteUsuarios}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
