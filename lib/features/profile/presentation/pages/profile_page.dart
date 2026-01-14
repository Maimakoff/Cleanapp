import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cleanapp/core/services/supabase_service.dart';
import 'package:cleanapp/core/widgets/bottom_nav_bar.dart';
import 'package:cleanapp/core/models/booking.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarUrl;
  Map<String, dynamic> _userStats = {};
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = SupabaseService.currentUser;
      if (user != null) {
        // Загружаем статистику пользователя
        final stats = await SupabaseService.getUserStats();
        
        // Загружаем историю заказов
        final bookings = await SupabaseService.getUserBookings(user.id);
        
        // Получаем URL аватара из metadata
        final avatarPath = user.userMetadata?['avatar_url'] as String?;
        String? avatarUrl;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          avatarUrl = SupabaseService.getAvatarUrl(avatarPath);
        }
        
        if (mounted) {
          setState(() {
            _userStats = stats;
            _bookings = bookings;
            _avatarUrl = avatarUrl;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      final user = SupabaseService.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Вы не авторизованы')),
          );
        }
        return;
      }

      // Показываем индикатор загрузки
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Загрузка аватара...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Читаем файл
      final imageBytes = await File(image.path).readAsBytes();
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Загружаем в Supabase Storage
      final url = await SupabaseService.uploadAvatar(user.id, imageBytes, fileName);

      // Обновляем профиль пользователя с путем к аватару
      await SupabaseService.updateUserProfile(avatarUrl: '${user.id}/$fileName');
      
      // Обновляем локальный URL
      setState(() {
        _avatarUrl = url;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Аватар успешно обновлен!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProfileData(); // Перезагружаем данные
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              if (mounted) {
                context.push('/settings');
              }
            },
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Вы не авторизованы',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Войти'),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadProfileData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header with Avatar
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      backgroundImage: _avatarUrl != null
                                          ? CachedNetworkImageProvider(_avatarUrl!)
                                          : null,
                                      child: _avatarUrl == null
                                          ? Text(
                                              user.email?.substring(0, 1).toUpperCase() ?? 'U',
                                              style: TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).scaffoldBackgroundColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                          onPressed: _pickAndUploadAvatar,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  user.userMetadata?['name'] as String? ?? 
                                  user.email?.split('@')[0] ?? 
                                  'Пользователь',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (user.email != null)
                                  Text(
                                    user.email!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // User Level (Геймификация)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.primary,
                                            Theme.of(context).colorScheme.secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, color: Colors.white, size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Уровень ${_userStats['level'] ?? 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_userStats['points'] ?? 0} баллов',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'До следующего уровня: ${_userStats['nextLevelPoints'] ?? 100} баллов',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: (_userStats['currentLevelPoints'] ?? 0) / 
                                           (_userStats['nextLevelPoints'] ?? 100),
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_userStats['currentLevelPoints'] ?? 0} / ${_userStats['nextLevelPoints'] ?? 100}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.check_circle,
                                label: 'Заказов',
                                value: '${_userStats['completedBookings'] ?? 0}',
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star,
                                label: 'Баллов',
                                value: '${_userStats['points'] ?? 0}',
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Menu Items
                        Text(
                          'Меню',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),

                        _ProfileMenuItem(
                          icon: Icons.history,
                          title: 'История заказов',
                          subtitle: '${_bookings.length} заказов',
                          onTap: () {
                            if (mounted) {
                              context.push('/orders-history');
                            }
                          },
                        ),

                        _ProfileMenuItem(
                          icon: Icons.settings,
                          title: 'Настройки',
                          subtitle: 'Пароль, уведомления',
                          onTap: () {
                            if (mounted) {
                              context.push('/settings');
                            }
                          },
                        ),

                        // Admin Panel
                        if (SupabaseService.isAdmin())
                          _ProfileMenuItem(
                            icon: Icons.admin_panel_settings,
                            title: 'Админ-панель',
                            subtitle: 'Управление заказами',
                            textColor: Colors.purple,
                            onTap: () {
                              if (mounted) {
                                context.push('/admin');
                              }
                            },
                          ),

                        // Cleaner Panel
                        if (SupabaseService.isCleaner())
                          _ProfileMenuItem(
                            icon: Icons.cleaning_services,
                            title: 'Панель клинера',
                            subtitle: 'Мои заказы',
                            textColor: Colors.blue,
                            onTap: () {
                              if (mounted) {
                                context.push('/cleaner');
                              }
                            },
                          ),

                        _ProfileMenuItem(
                          icon: Icons.help_outline,
                          title: 'Помощь и поддержка',
                          subtitle: 'FAQ, контакты',
                          onTap: () {
                            // Navigate to help
                          },
                        ),

                        const SizedBox(height: 16),

                        _ProfileMenuItem(
                          icon: Icons.logout,
                          title: 'Выйти',
                          textColor: Colors.red,
                          onTap: () async {
                            if (!mounted) return;
                            final router = GoRouter.of(context);
                            
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Выход'),
                                content: const Text('Вы уверены, что хотите выйти?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Отмена'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Выйти', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              if (!mounted) return;
                              await SupabaseService.signOut();
                              if (!mounted) return;
                              router.go('/auth');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: textColor?.withValues(alpha: 0.7) ?? Colors.grey,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: textColor == null
            ? Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
