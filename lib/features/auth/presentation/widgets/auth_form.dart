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
  DateTime? _lastSubmitTime; // Race condition protection

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

    // Double-submit protection
    if (_isLoading) return;

    // Race condition protection: prevent multiple rapid submissions
    final now = DateTime.now();
    if (_lastSubmitTime != null && 
        now.difference(_lastSubmitTime!).inMilliseconds < 2000) {
      return; // Ignore if submitted less than 2 seconds ago
    }
    _lastSubmitTime = now;

    setState(() => _isLoading = true);

    try {
      if (_isForgotPassword) {
        await SupabaseService.resetPassword(_emailController.text.trim())
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Превышено время ожидания. Проверьте интернет-соединение');
              },
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Письмо отправлено! Проверьте почту')),
          );
          setState(() => _isForgotPassword = false);
        }
      } else if (_isLogin) {
        final response = await SupabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Превышено время ожидания. Проверьте интернет-соединение');
          },
        );
        
        if (mounted) {
          // Проверяем, что сессия действительно создана
          if (response.session != null) {
          context.go('/');
          } else {
            throw Exception('Не удалось войти. Проверьте данные для входа');
          }
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
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Превышено время ожидания. Проверьте интернет-соединение и попробуйте снова');
          },
        );
        
        if (mounted) {
          // Check if email confirmation is required
          if (response.session == null && response.user != null) {
            // Email confirmation required
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Регистрация успешна! Проверьте почту для подтверждения email.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        try {
                          await SupabaseService.resendEmailConfirmation(
                            _emailController.text.trim(),
        );
        if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Письмо отправлено повторно!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ошибка: ${e.toString().replaceAll('Exception: ', '')}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Отправить письмо повторно'),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 10),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
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
        final errorLower = errorMessage.toLowerCase();
        
        // Handle timeout errors
        if (errorLower.contains('превышено время ожидания') ||
            errorLower.contains('timeout') ||
            errorLower.contains('timeoutexception')) {
          errorMessage = 'Превышено время ожидания. Проверьте интернет-соединение и попробуйте снова';
        }
        // Handle specific Supabase errors
        else if (errorLower.contains('supabase не инициализирован') ||
            errorLower.contains('supabase не настроен') ||
            errorLower.contains('_isinitialized') ||
            errorLower.contains('not initialized')) {
          errorMessage = 'Supabase не настроен. Проверьте файл .env с SUPABASE_URL и SUPABASE_ANON_KEY';
        }
        // Обработка ошибок входа (login)
        else if (_isLogin) {
          // Неверные учетные данные (Supabase не различает неверный email и пароль для безопасности)
          if (errorLower.contains('invalid login credentials') ||
              errorLower.contains('invalid credentials') ||
              errorLower.contains('invalid email or password')) {
            errorMessage = 'Неверный email или пароль. Проверьте правильность данных или зарегистрируйтесь, если у вас еще нет аккаунта';
          } 
          // Email не подтвержден
          else if (errorLower.contains('email not confirmed') ||
              errorLower.contains('email not verified') ||
              errorLower.contains('email не подтвержден')) {
            errorMessage = 'Email не подтвержден. Проверьте почту и подтвердите email перед входом';
          } 
          // Слишком много попыток
          else if (errorLower.contains('too many requests') ||
              errorLower.contains('rate limit') ||
              errorLower.contains('слишком много попыток')) {
            errorMessage = 'Слишком много попыток входа. Подождите немного и попробуйте снова';
          } 
          // Пользователь уже зарегистрирован (при попытке входа)
          else if (errorLower.contains('user already registered') ||
              errorLower.contains('already registered') ||
              errorLower.contains('email address is already')) {
            errorMessage = 'Пользователь с таким email уже зарегистрирован. Войдите в систему';
          } 
          // Пользователь не найден (старая проверка, обычно не используется Supabase)
          else if (errorLower.contains('email not found') ||
              errorLower.contains('user not found') ||
              errorLower.contains('пользователь не найден')) {
            errorMessage = 'Пользователь с таким email не найден. Проверьте правильность email или зарегистрируйтесь';
          } 
          // Неверный пароль (старая проверка, обычно не используется Supabase)
          else if (errorLower.contains('invalid password') ||
              errorLower.contains('wrong password') ||
              errorLower.contains('неверный пароль') ||
              errorLower.contains('incorrect password')) {
            errorMessage = 'Неверный пароль. Проверьте правильность пароля или воспользуйтесь восстановлением пароля';
          } 
          // Общая ошибка входа
          else {
            errorMessage = 'Не удалось войти. Проверьте правильность email и пароля';
          }
        }
        // Обработка ошибок регистрации (signup)
        else {
          if (errorLower.contains('user already registered') ||
              errorLower.contains('already registered') ||
              errorLower.contains('email address is already') ||
              errorLower.contains('user already exists')) {
            errorMessage = 'Пользователь с таким email уже зарегистрирован. Войдите в систему или используйте другой email';
          } else if (errorLower.contains('invalid email') ||
              errorLower.contains('invalid email format')) {
            errorMessage = 'Некорректный email адрес. Проверьте правильность ввода';
          } else if (errorLower.contains('password') && 
              (errorLower.contains('short') || errorLower.contains('weak') || errorLower.contains('too short'))) {
            errorMessage = 'Пароль должен быть не менее 6 символов';
          } else if (errorLower.contains('email rate limit') ||
              errorLower.contains('rate limit') ||
              errorLower.contains('too many requests')) {
            errorMessage = 'Слишком много запросов. Попробуйте позже';
          } else {
            errorMessage = 'Не удалось зарегистрироваться. Проверьте введенные данные и попробуйте снова';
          }
        }
        
        // Общие ошибки сети
        if (errorLower.contains('network') ||
            errorLower.contains('connection') ||
            errorLower.contains('socketexception') ||
            errorLower.contains('failed host lookup')) {
          errorMessage = 'Ошибка сети. Проверьте интернет-соединение и попробуйте снова';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage
                  .replaceAll('Exception: ', '')
                  .replaceAll('TimeoutException: ', '')
                  .replaceAll('AuthException: ', '')
                  .trim(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
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
              // Используем более строгую валидацию email
              if (value == null || value.trim().isEmpty) {
                return 'Введите email';
              }
              
              final emailRegex = RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              );
              
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Введите корректный email';
              }
              
              if (value.length > 255) {
                return 'Email слишком длинный';
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
                  onPressed: _isLoading 
                      ? null 
                      : () => setState(() => _isForgotPassword = true),
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
            onPressed: (_isLoading || !mounted) ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              disabledBackgroundColor: Colors.grey,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(_isForgotPassword
                    ? 'Отправить ссылку'
                    : _isLogin
                        ? 'Войти'
                        : 'Зарегистрироваться'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isLoading 
                ? null 
                : () {
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

