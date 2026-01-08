import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../../app.dart' show rootNavigatorKey;
import '../../../blocs/auth_bloc.dart';
import '../../../blocs/locale_cubit.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/di/injection.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/config_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../services/version_info.dart';
import '../../../models/user.dart';
import '../../../models/logout_reason.dart';
import '../../../l10n/app_localizations.dart';
import '../auth/oauth_logout_screen.dart';

Widget buildVersionBar(AppLocalizations l10n, {required String versionLabel}) {
  final currentYear = DateTime.now().year.toString();
  final copyrightText = l10n.copyrightNotice.replaceAll('{year}', currentYear);

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Center(
      child: Text(
        '${l10n.appVersion} $versionLabel - $copyrightText',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingTeams = false;
  bool _isUpdatingTeam = false;
  List<String> _teamOptions = [];

  @override
  void initState() {
    super.initState();
    // Fetch user info if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authRepository = getIt<AuthRepository>();
      if (authRepository.currentUser == null) {
        authRepository.fetchUserInfo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authRepository = getIt<AuthRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF37414A),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const _SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: authRepository.userStream,
        initialData: authRepository.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.threeRotatingDots(
                    color: const Color(0xFF2FB8AC),
                    size: 50,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.loadingProfile),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await authRepository.fetchUserInfo();
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User Avatar
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2FB8AC,
                            ).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2FB8AC),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // User Name
                      Center(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Username
                      Center(
                        child: Text(
                          '@${user.username}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // User Information Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.userInformation,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                context,
                                Icons.email,
                                l10n.email,
                                user.email,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                context,
                                Icons.phone,
                                l10n.phone,
                                user.phone,
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                context,
                                Icons.business,
                                l10n.tenant,
                                authRepository.tenantConfig?.tenant ?? l10n.na,
                              ),
                              const SizedBox(height: 12),
                              _buildTeamRow(
                                context,
                                user
                                        .config
                                        ?.onecarePersonalConfig
                                        ?.defaultTeam ??
                                    l10n.na,
                                l10n,
                                authRepository,
                              ),
                              const SizedBox(height: 12),
                              // Type removed per requirement
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Copyright at bottom
              Padding(
                padding: const EdgeInsets.all(24),
                child: buildVersionBar(
                  l10n,
                  versionLabel: context.read<VersionInfo>().label,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRow(
    BuildContext context,
    String currentTeam,
    AppLocalizations l10n,
    AuthRepository authRepository,
  ) {
    return InkWell(
      onTap: _isUpdatingTeam
          ? null
          : () => _onChangeTeam(context, authRepository, l10n, currentTeam),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.group, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.defaultTeam,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTeam,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _isUpdatingTeam
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: LoadingAnimationWidget.threeRotatingDots(
                        color: const Color(0xFF37414A),
                        size: 20,
                      ),
                    )
                  : const Icon(Icons.edit, size: 18, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onChangeTeam(
    BuildContext context,
    AuthRepository authRepository,
    AppLocalizations l10n,
    String currentTeam,
  ) async {
    setState(() {
      _isLoadingTeams = true;
    });

    final userRepository = getIt<UserRepository>();
    try {
      final teams = await userRepository.getUserTeams();
      _teamOptions = teams.map((t) => t['name'] as String).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
      setState(() {
        _isLoadingTeams = false;
      });
      return;
    }

    setState(() {
      _isLoadingTeams = false;
    });

    String? selectedTeam = currentTeam.isNotEmpty ? currentTeam : null;

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      l10n.defaultTeam,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingTeams)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: LoadingAnimationWidget.threeRotatingDots(
                          color: const Color(0xFF37414A),
                          size: 40,
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _teamOptions.length,
                          itemBuilder: (context, index) {
                            final name = _teamOptions[index];
                            final isSelected = name == selectedTeam;
                            return ListTile(
                              title: Text(name),
                              trailing: isSelected
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                setModalState(() {
                                  selectedTeam = name;
                                });
                                Navigator.pop(context, name);
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _isUpdatingTeam = true;
    });

    try {
      await userRepository.updateDefaultTeam(selected);
      await authRepository.fetchUserInfo();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.success)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingTeam = false;
        });
      }
    }
  }
}

class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  bool _showHiddenButton = false;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = context.select(
      (LocaleCubit cubit) => cubit.state.languageCode,
    );

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF37414A), Color(0xFF2FB8AC)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.settings,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.preferencesAndOptions,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Language Selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2FB8AC).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.language, color: Color(0xFF2FB8AC)),
                  ),
                  title: Text(
                    l10n.language,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _getLanguageName(localeCode),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF2FB8AC),
                  ),
                  onTap: () => _showLanguageDialog(context, l10n),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  GestureDetector(
                    onLongPressStart: (_) {
                      _longPressTimer = Timer(const Duration(seconds: 5), () {
                        if (mounted) {
                          setState(() {
                            _showHiddenButton = true;
                          });
                          HapticFeedback.heavyImpact();
                        }
                      });
                    },
                    onLongPressEnd: (_) {
                      if (!_showHiddenButton) {
                        _longPressTimer?.cancel();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[100]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.logout, color: Colors.red),
                        ),
                        title: Text(
                          l10n.logout,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          l10n.signOutDescription,
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.red,
                        ),
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(l10n.logout),
                              content: Text(l10n.areYouSureLogout),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: Text(l10n.cancel),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(l10n.logout),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            // First, logout from IAM via OAuth logout screen
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (context) => const OAuthLogoutScreen(),
                              ),
                            );

                            // Then clear local tokens regardless of IAM logout success
                            if (context.mounted) {
                              context.read<AuthBloc>().add(
                                const LogoutRequested(),
                              );
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(AppRoutes.login);
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  // Hidden button that appears after 5-second long press
                  if (_showHiddenButton) ...[
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings_backup_restore,
                            color: Colors.orange,
                          ),
                        ),
                        title: Text(
                          l10n.resetConfiguration,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          l10n.resetConfigurationDescription,
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.orange,
                        ),
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(l10n.resetConfigurationTitle),
                              content: Text(l10n.resetConfigurationMessage),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: Text(l10n.cancel),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(l10n.reset),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            // First, logout from IAM via OAuth logout screen
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (context) => const OAuthLogoutScreen(),
                              ),
                            );

                            // Then clear configuration and local tokens
                            if (context.mounted) {
                              await getIt<ConfigRepository>().clearConfig();
                              context.read<AuthBloc>().add(
                                const LogoutRequested(
                                  reason: LogoutReason.configReset,
                                ),
                              );

                              // Navigate back to app root using global navigator
                              // ConfigWrapper will detect no config and show the
                              // "Welcome to SIGO OneCare" screen with QR scan button
                              final navigator = rootNavigatorKey.currentState;
                              if (navigator != null) {
                                navigator.pushNamedAndRemoveUntil(
                                  '/',
                                  (route) => false,
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    final languageNames = {
      'en': 'English',
      'pt': 'Portugues',
      'fr': 'Francais',
      'de': 'Deutsch',
    };
    return languageNames[code] ?? code.toUpperCase();
  }

  void _showLanguageDialog(BuildContext context, AppLocalizations l10n) {
    final languages = [
      {'code': 'en', 'name': 'English', 'nativeName': 'English'},
      {'code': 'pt', 'name': 'Portuguêse', 'nativeName': 'Português'},
      {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
      {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2FB8AC).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.language, color: Color(0xFF2FB8AC)),
            ),
            const SizedBox(width: 12),
            Text(l10n.language),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSelected =
                context.read<LocaleCubit>().state.languageCode == lang['code'];
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2FB8AC).withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    lang['code']!.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF2FB8AC)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              title: Text(
                lang['nativeName']!,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF2FB8AC) : Colors.black,
                ),
              ),
              subtitle: Text(
                lang['name']!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF2FB8AC))
                  : null,
              onTap: () async {
                await context.read<LocaleCubit>().setLocale(
                  Locale(lang['code']!),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${l10n.languageChanged} ${lang['nativeName']}',
                      ),
                      backgroundColor: const Color(0xFF2FB8AC),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
