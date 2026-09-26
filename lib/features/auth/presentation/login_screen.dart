import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepo = AuthRepository();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función puente entre la UI y la lógica
  Future<void> _procesarLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await _authRepo.iniciarSesion(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (error == null) {

      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [


          Positioned.fill(
            child: Image.asset(
              'assets/fondo.jpg',
              fit: BoxFit.cover,
            ),
          ),


          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),


          Center(
            child: Container(
              width: 400,


              // Espacio interno del box
              padding: const EdgeInsets.all(30.0),

              // Separación de los lados de la pantalla
              margin: const EdgeInsets.symmetric(
                horizontal: 20.0,
              ),

              // Diseño del box
              decoration: BoxDecoration(
                color: const Color(0xFF121212),

                // Bordes redondeados
                borderRadius: BorderRadius.circular(35.0),

                // Sombra
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.17),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),


              child: Form(
                key: _formKey,
                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30.0),
                      child:  Image.asset
                      (
                      'assets/logo.jpg',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                      ),
                ),



                    const SizedBox(height: 20),


                    const Text(
                      'Bienvenido',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),


                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Correo',
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                        ),

                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.white70,
                        ),

                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),

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
                          borderSide: const BorderSide(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      validator: (val) =>
                          val != null && val.contains('@')
                              ? null
                              : 'Ingresa un correo valido',
                    ),

              const SizedBox(height: 22),



                    TextFormField(
                      controller: _passwordController,
                      obscureText: _ocultarPassword,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                        ),

                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white70,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _ocultarPassword = !_ocultarPassword;
                            });
                          },
                        ),

                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),

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
                          borderSide: const BorderSide(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      validator: (val) =>
                          val != null && val.isNotEmpty
                              ? null
                              : 'Ingresa tu contraseña',
                    ),

                     const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {

                    context.go('/RecuperarContrasena');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),

                    const SizedBox(height: 24),

                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _procesarLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFC6FF00),

                                foregroundColor:
                                    Colors.black,

                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                'ENTRAR',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes cuenta?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go('/registro');
                          },
                          style: TextButton.styleFrom(

                            foregroundColor:  const Color(0xFFC6FF00),
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                          child: const Text('Regístrate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}