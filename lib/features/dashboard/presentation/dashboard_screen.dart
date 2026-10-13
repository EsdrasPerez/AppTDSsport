import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../quinielas/presentation/quinielas_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1E293B),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                _selectedIndex == 1 ? 'Módulo de Quinielas' : 'TD Sport',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar()),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 1:
        return const QuinielasScreen();
      default:
        return _buildMainContent();
    }
  }

  Widget _buildSidebar() {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['nombre'] ?? user?.email?.split('@').first ?? 'Usuario';
    final userEmail = user?.email ?? 'usuario@tdsport.com';

    return Container(
      width: 250,
      color: const Color(0xFF1E293B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                Icon(Icons.sports_soccer, color: Color(0xFF3B82F6), size: 28),
                SizedBox(width: 10),
                Text(
                  'TD Sport',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        userEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildNavItem(0, 'Panel Principal', Icons.dashboard),
          _buildNavItem(1, 'Quinielas Activas', Icons.people_alt_rounded),
          _buildNavItem(2, 'Mis Pronósticos', Icons.sports),
          _buildNavItem(3, 'Ranking Global', Icons.emoji_events),
          _buildNavItem(4, 'Suscripción', Icons.star_border),
          const Spacer(),
          _buildNavItem(5, 'Configuraciones', Icons.settings),
          _buildCerrarSesionItem(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // Si estamos en móvil, cerramos el drawer
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCerrarSesionItem() {
    return InkWell(
      onTap: () async {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          context.go('/login');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 15),
            Text(
              'Cerrar Sesión',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Resumen General',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Monitor de estado del sistema y acceso a quinielas.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Sistema en Línea',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 25),

          // Banner de acceso directo a Quinielas
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '¡Módulo de Quinielas Deportivo!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Crea una nueva quiniela con código de invitación único o únete a una existente con tu código.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Crear Quiniela'),
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.group_add, color: Color(0xFF34D399), size: 18),
                      label: const Text('Unirme'),
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildSummaryCard('TORNEOS', '6', 'Activos', Icons.emoji_events, const Color(0xFF10B981)),
              _buildSummaryCard('QUINIELAS', 'Activas', 'Ver módulo', Icons.people_alt, const Color(0xFF3B82F6), onTap: () {
                setState(() => _selectedIndex = 1);
              }),
              _buildSummaryCard('PENDIENTES', '0', 'Por verificar', Icons.assignment_late, const Color(0xFFEF4444)),
              _buildSummaryCard('USUARIOS', 'Online', 'Registrados', Icons.people_outline, const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actividad Reciente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Ver Todo ➔', style: TextStyle(color: Color(0xFF3B82F6))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActivityTable(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, IconData icon, Color iconColor, {bool isWarning = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(icon, color: Colors.white54, size: 20),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: TextStyle(
                color: iconColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (isWarning) const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 14),
                if (title == 'TORNEOS') const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isWarning ? const Color(0xFFEF4444) : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('EVENTO', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('TIPO', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('ESTADO', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('HORA', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right,)),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          _buildActivityRow('Liga Bantrab', 'Torneo Activo', 'En Curso', const Color(0xFF10B981), 'Hoy', Icons.emoji_events, const Color(0xFF3B82F6)),
          _buildActivityRow('Módulo Quinielas', 'RPC Conectado', 'Activo', const Color(0xFF10B981), 'Ahora', Icons.check_circle, const Color(0xFF10B981)),
          _buildActivityRow('Concacaf 2026', 'Torneo Activo', 'En Curso', const Color(0xFF10B981), 'Hoy', Icons.sports_soccer, const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(String event, String type, String status, Color statusColor, String time, IconData icon, Color iconBg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconBg, size: 16),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    event,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(type, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(time, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
