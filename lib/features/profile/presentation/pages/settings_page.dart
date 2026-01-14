import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cleanapp/core/services/supabase_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _notificationsEnabled = true;
  bool _isLoadingNotifications = true;
  String _selectedLanguage = 'ru';
  bool _isLoadingLanguage = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationsSetting();
    _loadLanguageSetting();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationsSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      setState(() {
        _notificationsEnabled = true;
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Уведомления включены' : 'Уведомления выключены',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _notificationsEnabled = !value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось сохранить настройки'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    try {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        throw Exception('Пароли не совпадают');
      }

      await SupabaseService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Превышено время ожидания');
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пароль успешно изменен!'),
            backgroundColor: Colors.green,
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (errorMessage.contains('Неверный текущий пароль')) {
          errorMessage = 'Неверный текущий пароль';
        } else if (errorMessage.contains('timeout')) {
          errorMessage = 'Превышено время ожидания. Проверьте интернет-соединение';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  Future<void> _loadLanguageSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedLanguage = prefs.getString('selected_language') ?? 'ru';
        _isLoadingLanguage = false;
      });
    } catch (e) {
      setState(() {
        _selectedLanguage = 'ru';
        _isLoadingLanguage = false;
      });
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'kk':
        return 'Қазақша';
      default:
        return 'Русский';
    }
  }

  Future<void> _showLanguageDialog() async {
    final languages = [
      {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'kk', 'name': 'Қазақша', 'flag': '🇰🇿'},
    ];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите язык'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSelected = lang['code'] == _selectedLanguage;
            return ListTile(
              leading: Text(
                lang['flag']!,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(lang['name']!),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => Navigator.pop(context, lang['code']),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null && selected != _selectedLanguage) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_language', selected);
        setState(() {
          _selectedLanguage = selected;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Язык изменен на ${_getLanguageName(selected)}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Не удалось сохранить язык'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: user == null
          ? const Center(child: Text('Вы не авторизованы'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Account Section
                Text(
                  'Аккаунт',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(user.email ?? 'Не указан'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Смена email временно недоступна'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: const Text('Телефон'),
                        subtitle: Text(
                          user.userMetadata?['phone'] as String? ?? 'Не указан',
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Смена телефона временно недоступна'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Security Section
                Text(
                  'Безопасность',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Изменить пароль',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Текущий пароль',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrentPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureCurrentPassword = !_obscureCurrentPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureCurrentPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите текущий пароль';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Новый пароль',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureNewPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите новый пароль';
                              }
                              if (value.length < 6) {
                                return 'Пароль должен быть не менее 6 символов';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Подтвердите новый пароль',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Подтвердите пароль';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Пароли не совпадают';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isChangingPassword ? null : _changePassword,
                              child: _isChangingPassword
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Изменить пароль'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Other Settings
                Text(
                  'Другое',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: const Text('Уведомления'),
                        trailing: _isLoadingNotifications
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Switch(
                                value: _notificationsEnabled,
                                onChanged: _toggleNotifications,
                              ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Язык'),
                        subtitle: _isLoadingLanguage
                            ? const Text('Загрузка...')
                            : Text(_getLanguageName(_selectedLanguage)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: _showLanguageDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('О приложении'),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'Cleanapp',
                            applicationVersion: '1.0.0',
                            applicationIcon: const Icon(Icons.cleaning_services),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
