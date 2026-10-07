import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/auth_repository.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final AuthRepository _authRepo = AuthRepository();

  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _confirmarPasswordController = TextEditingController();
  bool _obscureConfirmPassword = true;

  // Colors based on mockup
  final Color _bgColor = const Color(0xFF121212); // Fondo oscuro
  final Color _primaryGreen = const Color(0xFFC6FF00); // Verde neón
  final Color _fieldBgColor = const Color(0xFF2C2C2C); // Fondo de campos (igual que login)
  final Color _textColor = Colors.white;
  final Color _hintColor = Colors.white30;
  final Color _labelColor = Colors.white70; 
  
  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _evaluarSeguridadContrasena(String password) {
  if (password.length < 6) return 'Débil';
  if (!password.contains(RegExp(r'[0-9]'))) return 'Media';
  if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return 'Media';
  if (password.length >= 8) return 'Fuerte';
  return 'Media';
  }
  
  Future<void> _procesarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await _authRepo.registrarUsuario(
      nombre: _nombreController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _registroConGoogle() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro con Google en desarrollo')),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          style: TextStyle(color: _textColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _labelColor),
            hintText: hintText,
            hintStyle: TextStyle(color: _hintColor, fontSize: 14),
            prefixIcon: Icon(prefixIcon, color: _hintColor, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _hintColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: _fieldBgColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Colors.white, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Align(
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30.0),
                      child:  Image.asset(
                        'assets/logo.jpg',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Título principal
                  Text(
                    'Únete a la liga. Domina las predicciones.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Indicador de progreso (tres líneas)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _primaryGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF344054),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF344054),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Input de Nombre
                  _buildTextField(
                    label: 'Nombre Completo',
                    controller: _nombreController,
                    hintText: 'Ej. Carlos Silva',
                    prefixIcon: Icons.person_outline,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'El nombre es requerido'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // Input de Correo
                  _buildTextField(
                    label: 'Correo Electrónico',
                    controller: _emailController,
                    hintText: 'atleta@dominio.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'El correo es requerido';
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(val.trim())) return 'Ingresa un correo válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  

                  // Input de Contraseña
                  _buildTextField(
                    label: 'Contraseña Segura',
                    controller: _passwordController,
                    hintText: '******',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'La contraseña es requerida';
                      final seguridad = _evaluarSeguridadContrasena(val);
                      if (seguridad == 'Débil') {
                        if (val.length < 8) return 'Mínimo 8 caracteres';
                        if (!val.contains(RegExp(r'[0-9]'))) return 'Debe contener un número';
                        return 'Debe contener un símbolo';
                      }
                      return null;
                    },
                  ),
                 
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _passwordController,
                    builder: (context, value, child) {
                      // Aquí usamos tu función con el texto actual que va escribiendo el usuario
                      String nivel = _evaluarSeguridadContrasena(value.text);
                      
                    
                      Color colorNivel = Colors.red;
                      if (nivel == 'Fuerte') colorNivel = Colors.green;
                      if (nivel == 'Media') colorNivel = Colors.orange;

                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Seguridad de la contraseña: $nivel',
                          style: GoogleFonts.spaceMono(
                            color: value.text.isEmpty ? Colors.transparent : colorNivel,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),

                  Text(
                    'Mínimo 8 caracteres, números y símbolos.',
                    style: GoogleFonts.spaceMono(
                      color: _hintColor,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 8),

                 

                   _buildTextField(
                    label: 'Confirma tu Contraseña',
                    controller: _confirmarPasswordController,
                    hintText: '******',
                    prefixIcon: Icons.lock_outline,
                    isPassword: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Confirma tu contraseña';
                      if (val != _passwordController.text) return 'Las contraseñas no coinciden'; 
                      return null;            
        
                    },
                  ),

                  const SizedBox(height: 32),

                  

                  // Botón Registrarse
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _procesarRegistro,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ), 
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Registrarse',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                  const SizedBox(height: 24),
                  
                  // Ya tienes cuenta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: GoogleFonts.inter(
                          color: _textColor,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Inicia Sesión',
                          style: GoogleFonts.inter(
                            color: _primaryGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Separador
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFF344054))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'O INGRESA CON',
                          style: GoogleFonts.spaceMono(
                            color: _hintColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFF344054))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón de Google
                  OutlinedButton.icon(
                    onPressed: _registroConGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Color(0xFF344054)),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'G',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    label: Text(
                      'Google',
                      style: GoogleFonts.inter(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Footer Text
                  Text(
                    'Al registrarte, aceptas nuestros Términos de Servicio y Política de Privacidad.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _hintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
