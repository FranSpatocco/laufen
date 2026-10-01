import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/laufen_wordmark.dart';

/// Email/password + Google login and registration. Pushed on demand (from
/// Perfil, Historial, the landing, or when saving a run) and pops with
/// `true` on success, so the caller can continue what it was doing — e.g.
/// live_run_screen.dart saves the pending run right after.
class LoginScreen extends StatefulWidget {
  /// Opens in "Crear cuenta" mode instead of "Iniciar sesión".
  final bool startRegistering;

  /// Why we're asking, shown above the form (e.g. "to save your run").
  final String? reason;

  const LoginScreen({super.key, this.startRegistering = false, this.reason});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  late bool _isRegistering = widget.startRegistering;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithGoogle();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_isRegistering) {
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('invalid-email')) return 'Email inválido.';
    if (raw.contains('user-not-found')) {
      return 'No existe una cuenta con ese email.';
    }
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Contraseña incorrecta.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'Ya existe una cuenta con ese email.';
    }
    if (raw.contains('weak-password')) {
      return 'La contraseña es muy débil (mínimo 6 caracteres).';
    }
    return 'Ocurrió un error. Intentá de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Crear cuenta' : 'Iniciar sesión'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: LaufenWordmark(fontSize: 32, color: AppTheme.accent),
                    ),
                    const SizedBox(height: 24),
                    if (widget.reason != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline, color: AppTheme.accentDark, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(widget.reason!)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          (value == null || !value.contains('@'))
                          ? 'Ingresá un email válido'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                      validator: (value) => (value == null || value.length < 6)
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isRegistering
                                  ? 'Crear cuenta'
                                  : 'Iniciar sesión',
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(
                              () => _isRegistering = !_isRegistering,
                            ),
                      child: Text(
                        _isRegistering
                            ? '¿Ya tenés cuenta? Iniciá sesión'
                            : '¿No tenés cuenta? Registrate',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('o'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      child: const Text('Continuar con Google'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
