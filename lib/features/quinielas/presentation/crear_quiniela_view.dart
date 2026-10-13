import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/quinielas_repository.dart';
import '../models/torneo_model.dart';
import 'widgets/codigo_exito_dialog.dart';

class CrearQuinielaView extends StatefulWidget {
  final VoidCallback? onQuinielaCreada;

  const CrearQuinielaView({
    Key? key,
    this.onQuinielaCreada,
  }) : super(key: key);

  @override
  State<CrearQuinielaView> createState() => _CrearQuinielaViewState();
}

class _CrearQuinielaViewState extends State<CrearQuinielaView> {
  final _formKey = GlobalKey<FormState>();
  final _quinielasRepo = QuinielasRepository();

  final _nombreController = TextEditingController();
  final _limiteController = TextEditingController(text: '20');

  List<TorneoModel> _torneos = [];
  TorneoModel? _torneoSeleccionado;
  bool _cargandoTorneos = true;
  String? _errorTorneos;

  bool _isSubmitting = false;
  String? _codigoGenerado;
  String? _errorSubmit;

  @override
  void initState() {
    super.initState();
    _cargarTorneosActivos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _limiteController.dispose();
    super.dispose();
  }

  Future<void> _cargarTorneosActivos() async {
    setState(() {
      _cargandoTorneos = true;
      _errorTorneos = null;
    });

    try {
      final torneos = await _quinielasRepo.getTorneosActivos();
      setState(() {
        _torneos = torneos;
        _cargandoTorneos = false;
        if (torneos.isNotEmpty) {
          _torneoSeleccionado = torneos.first;
        }
      });
    } catch (e) {
      setState(() {
        _errorTorneos = 'No se pudieron cargar los torneos. Toca para reintentar.';
        _cargandoTorneos = false;
      });
    }
  }

  Future<void> _guardarQuiniela() async {
    if (!_formKey.currentState!.validate()) return;

    if (_torneoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un torneo activo.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final int limite = int.tryParse(_limiteController.text.trim()) ?? 20;

    setState(() {
      _isSubmitting = true;
      _errorSubmit = null;
    });

    final resultado = await _quinielasRepo.crearQuiniela(
      nombre: _nombreController.text.trim(),
      torneoId: _torneoSeleccionado!.id,
      limite: limite,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (resultado.success && resultado.codigo != null) {
      setState(() {
        _codigoGenerado = resultado.codigo;
      });

      // Mostrar diálogo modal con el código generado para compartir
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CodigoExitoDialog(
          codigo: resultado.codigo!,
          nombreQuiniela: _nombreController.text.trim(),
          torneoNombre: _torneoSeleccionado!.nombre,
          limite: limite,
          onContinuar: () {
            _limiteController.text = '20';
            _nombreController.clear();
            if (widget.onQuinielaCreada != null) {
              widget.onQuinielaCreada!();
            }
          },
        ),
      );
    } else {
      setState(() {
        _errorSubmit = resultado.error ?? 'Ocurrió un error al crear la quiniela.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorSubmit!),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1E293B),
                      const Color(0xFF1E293B).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: Color(0xFF60A5FA),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crear Nueva Quiniela',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configura el torneo, cupo y comparte el código generado.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Formulario
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo 1: Nombre de la quiniela
                      _buildEtiqueta('Nombre de la Quiniela', Icons.emoji_events_outlined),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombreController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          hint: 'Ej. Amigos del Trabajo, Torneo Familiar...',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre de la quiniela es obligatorio.';
                          }
                          if (value.trim().length < 3) {
                            return 'Debe tener al menos 3 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      // Campo 2: Selector de Torneos Activos
                      _buildEtiqueta('Torneo Activo', Icons.sports_soccer_outlined),
                      const SizedBox(height: 8),
                      _buildSelectorTorneos(),
                      const SizedBox(height: 22),

                      // Campo 3: Límite de participantes
                      _buildEtiqueta('Límite de Participantes', Icons.group_outlined),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _limiteController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration(
                          hint: 'Ej. 20',
                          prefixIcon: Icons.people_alt_outlined,
                          suffixText: 'jugadores',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un límite de participantes.';
                          }
                          final n = int.tryParse(value.trim());
                          if (n == null || n <= 0) {
                            return 'El límite debe ser mayor a 0.';
                          }
                          if (n > 500) {
                            return 'El límite máximo recomendado es 500.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Botones rápidos de selección de cupo
                      Wrap(
                        spacing: 8,
                        children: [5, 10, 20, 50, 100].map((cupo) {
                          final isSelected = _limiteController.text == cupo.toString();
                          return ActionChip(
                            label: Text('$cupo'),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            backgroundColor: isSelected
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF0F172A),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF60A5FA) : Colors.white12,
                            ),
                            onPressed: () {
                              setState(() {
                                _limiteController.text = cupo.toString();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),

                      // Mensaje de error si hubo
                      if (_errorSubmit != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorSubmit!,
                                  style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Botón de guardar e invocar RPC
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _guardarQuiniela,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          child: _isSubmitting
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 14),
                                    Text(
                                      'Generando Quiniela...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.vpn_key_rounded, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Guardar y Generar Código',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tarjeta fija del último código generado (si existe)
              if (_codigoGenerado != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.share_rounded, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Último Código Generado:',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _codigoGenerado!,
                              style: const TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar código',
                        icon: const Icon(Icons.copy_rounded, color: Colors.white),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _codigoGenerado!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código copiado al portapapeles'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEtiqueta(String texto, IconData icono) {
    return Row(
      children: [
        Icon(icono, size: 16, color: const Color(0xFF60A5FA)),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20),
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  Widget _buildSelectorTorneos() {
    if (_cargandoTorneos) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: const [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
            ),
            SizedBox(width: 14),
            Text(
              'Cargando torneos activos...',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_errorTorneos != null) {
      return InkWell(
        onTap: _cargarTorneosActivos,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.refresh, color: Color(0xFFEF4444), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _errorTorneos!,
                  style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_torneos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: const Text(
          'No hay torneos activos disponibles en este momento.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      );
    }

    return DropdownButtonFormField<TorneoModel>(
      value: _torneoSeleccionado,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _buildInputDecoration(
        hint: 'Selecciona un torneo',
        prefixIcon: Icons.emoji_events,
      ),
      items: _torneos.map((torneo) {
        return DropdownMenuItem<TorneoModel>(
          value: torneo,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  torneo.nombre,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  torneo.estadoTexto,
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (nuevo) {
        setState(() {
          _torneoSeleccionado = nuevo;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Debes seleccionar un torneo activo.';
        }
        return null;
      },
    );
  }
}
