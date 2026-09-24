import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

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
              title: const Text(
                'Quiniela Deportiva',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
      drawer: isDesktop ? null : _buildSidebar(),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
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
                Icon(Icons.sports_soccer, color: Colors.white, size: 28),
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
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal.shade700,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Admin Usuario',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Admin del Sistema',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildNavItem(0, 'Panel Principal', Icons.dashboard),
          _buildNavItem(1, 'Quinielas Activas', Icons.people),
          _buildNavItem(2, 'Mis Pronósticos', Icons.sports),
          _buildNavItem(3, 'Ranking Global', Icons.emoji_events),
          _buildNavItem(4, 'Suscripción', Icons.star_border),
          const Spacer(),
          _buildNavItem(5, 'Configuraciones', Icons.settings),
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
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    'Monitor de estado del sistema.',
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
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildSummaryCard('TORNEOS', '2', 'Activos', Icons.emoji_events, const Color(0xFF10B981)),
              _buildSummaryCard('PARTIDOS', '5', 'En vivo', Icons.sports_soccer, const Color(0xFF3B82F6)),
              _buildSummaryCard('PENDIENTES', '1', 'Por verificar', Icons.assignment_late, const Color(0xFFEF4444), isWarning: true),
              _buildSummaryCard('USUARIOS', '12', 'Registrados', Icons.people_outline, const Color(0xFFF59E0B)),
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

  Widget _buildSummaryCard(String title, String value, String subtitle, IconData icon, Color iconColor, {bool isWarning = false}) {
    return Container(
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
          _buildActivityRow('Jornada 1', 'Torneo Creado', 'Éxito', const Color(0xFF10B981), '10:42 AM', Icons.add_circle_outline, const Color(0xFF3B82F6)),
          _buildActivityRow('ID: #84', 'Cuotas', 'Procesado', Colors.grey, '10:15 AM', Icons.update, Colors.grey),
          _buildActivityRow('ID: #85', 'Manual', 'Pendiente', const Color(0xFFEF4444), '09:55 AM', Icons.gavel, const Color(0xFFEF4444)),
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
                // Se agregó Expanded aquí para evitar el error de desbordamiento (Right Overflow)
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
