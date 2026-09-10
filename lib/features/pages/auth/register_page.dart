import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:urbanogo/features/pages/auth/cubit/auth_cubit.dart';
import 'package:urbanogo/features/pages/home_map_page.dart';

class RegisterPage extends StatefulWidget {
  final String flavor;

  const RegisterPage({super.key, required this.flavor});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _carController = TextEditingController();
  final _plateController = TextEditingController();

  bool get _isDriver => widget.flavor == 'motorista';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _carController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _snack('Preencha nome, email e senha.');
      return;
    }
    if (password.length < 8) {
      _snack('A senha precisa ter ao menos 8 caracteres.');
      return;
    }

    context.read<AuthCubit>().register(
      name: name,
      email: email,
      password: password,
      phone: _phoneController.text.trim(),
      isDriver: _isDriver,
      vehicleModel: _carController.text.trim(),
      vehiclePlate: _plateController.text.trim(),
    );
  }

  void _onAuthState(BuildContext context, AuthState state) {
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrent) return;

    if (state.status == AuthStatus.authenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeMapPage(flavor: widget.flavor)),
      );
    } else if (state.status == AuthStatus.failure) {
      _snack(state.errorMessage ?? 'Não foi possível criar a conta.');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isDriver ? 'Cadastro de Motorista' : 'Criar Conta',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: _onAuthState,
        builder: (context, state) {
          final busy = state.isSubmitting;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nome completo',
                    icon: Icons.person,
                    enabled: !busy,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    icon: Icons.phone,
                    enabled: !busy,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    enabled: !busy,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Senha (mín. 8 caracteres)',
                    icon: Icons.lock,
                    isPassword: true,
                    enabled: !busy,
                  ),
                  const SizedBox(height: 16),

                  if (_isDriver) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _carController,
                            label: 'Carro (ex: Onix)',
                            icon: Icons.directions_car,
                            enabled: !busy,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _plateController,
                            label: 'Placa',
                            icon: Icons.credit_card,
                            enabled: !busy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Cadastrar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
