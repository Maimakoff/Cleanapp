import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cleanapp/core/services/supabase_service.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isForgotPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isForgotPassword) {
        await SupabaseService.resetPassword(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Письмо отправлено! Проверьте почту')),
          );
          setState(() => _isForgotPassword = false);
        }
      } else if (_isLogin) {
        await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          context.go('/');
        }
      } else {
        final response = await SupabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'referral_code': _referralController.text.trim().toUpperCase(),
          },
        );
        
        if (mounted) {
          // Check if email confirmation is required
          if (response.session == null && response.user != null) {
            // Email confirmation required
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Регистрация успешна! Проверьте почту для подтверждения email. '
                  'После подтверждения вы сможете войти в аккаунт.',
                ),
                duration: Duration(seconds: 5),
                backgroundColor: Colors.orange,
              ),
            );
            // Switch to login mode
            setState(() {
              _isLogin = true;
            });
          } else if (response.session != null) {
            // User is automatically logged in (email confirmation disabled)
            context.go('/');
          } else {
            // Registration failed
            throw Exception('Не удалось зарегистрироваться');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        
        // Handle specific Supabase errors
        if (errorMessage.contains('User already registered')) {
          errorMessage = 'Пользователь с таким email уже зарегистрирован';
        } else if (errorMessage.contains('Invalid email')) {
          errorMessage = 'Некорректный email адрес';
        } else if (errorMessage.contains('Password')) {
          errorMessage = 'Пароль должен быть не менее 6 символов';
        } else if (errorMessage.contains('Email rate limit')) {
          errorMessage = 'Слишком много запросов. Попробуйте позже';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage.replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isLogin && !_isForgotPassword) ...[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                hintText: 'Ваше имя',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите имя';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Номер телефона',
                hintText: '+7 (___) ___-__-__',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите телефон';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referralController,
              decoration: const InputDecoration(
                labelText: 'Реферальный код (необязательно)',
                hintText: 'Введите код друга',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'your@email.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите email';
              }
              if (!value.contains('@')) {
                return 'Введите корректный email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (!_isForgotPassword) ...[
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                hintText: '••••••••',
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите пароль';
                }
                if (value.length < 6) {
                  return 'Пароль должен быть не менее 6 символов';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            if (_isLogin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _isForgotPassword = true),
                  child: const Text('Забыли пароль?'),
                ),
              ),
          ] else
            Text(
              'Мы отправим ссылку для сброса пароля на этот email',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isForgotPassword
                    ? 'Отправить ссылку'
                    : _isLogin
                        ? 'Войти'
                        : 'Зарегистрироваться'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                if (_isForgotPassword) {
                  _isForgotPassword = false;
                } else {
                  _isLogin = !_isLogin;
                }
              });
            },
            child: Text(
              _isForgotPassword
                  ? 'Вернуться к входу'
                  : _isLogin
                      ? 'Нет аккаунта? Зарегистрируйтесь'
                      : 'Уже есть аккаунт? Войдите',
            ),
          ),
        ],
      ),
    );
  }
}

