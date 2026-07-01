import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/purchases_viewmodel.dart';

class _SettingsTexts {
  static const title = 'Ajustes';
  static const defaultSubtitle =
      'Gerencie dados locais, preferências e informações do app.';

  static const userConnected = 'Usuário conectado';
  static const localDataTitle = 'Dados salvos localmente';
  static const localDataSubtitle =
      'As informações permanecem salvas para este usuário mesmo ao atualizar ou fechar o app.';

  static const localDataSection = 'Gerenciar dados locais';
  static const restoreCategoriesTitle = 'Restaurar categorias padrão';
  static const restoreCategoriesSubtitle =
      'Reativa e recria as categorias principais do app sem apagar produtos ou compras.';

  static const clearAllDataTitle = 'Limpar todos os dados';
  static const clearAllDataSubtitle =
      'Apaga produtos, compras, itens e relatórios deste usuário.';

  static const accountSection = 'Conta';
  static const logoutTitle = 'Sair da conta';
  static const logoutSubtitle =
      'Encerra a sessão atual e volta para a tela de login. Seus dados continuam salvos.';

  static const aboutSection = 'Sobre o app';
  static const appName = 'Feira Mensal';
  static const appDescription =
      'Controle de compras de mercado, produtos, categorias e relatórios.';

  static const storageTitle = 'Armazenamento';
  static const storageDescription =
      'Os dados estão sendo salvos localmente por usuário neste dispositivo.';

  static const versionTitle = 'Versão';
  static const versionValue = '1.0.0';

  static const restoreSuccess = 'Categorias padrão restauradas com sucesso.';
  static const clearAllSuccess =
      'Todos os dados deste usuário foram apagados com sucesso.';

  static const cancel = 'Cancelar';

  static const restoreDialogTitle = 'Restaurar categorias padrão?';
  static const restoreDialogMessage =
      'Essa ação recriará e reativará as categorias padrão do app, sem apagar produtos ou compras já cadastrados.';
  static const restoreDialogConfirm = 'Restaurar';

  static const clearDialogTitle = 'Limpar todos os dados?';
  static const clearDialogMessage =
      'Essa ação apagará produtos, compras, itens e relatórios deste usuário. Essa ação não pode ser desfeita.';
  static const clearDialogConfirm = 'Limpar dados';

  static const logoutDialogTitle = 'Sair da conta?';
  static const logoutDialogMessage =
      'Sua sessão será encerrada e você voltará para a tela de login. Seus dados continuarão salvos.';
  static const logoutDialogConfirm = 'Sair';
}

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  _SettingsConfirmationAction? _confirmationAction;
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  bool _isConfirmingAction = false;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final productsState = ref.watch(productsProvider);
    final purchasesState = ref.watch(purchasesProvider);

    final currentUser = authState.currentUser;

    final categoriesCount = productsState.categories.length;
    final productsCount = productsState.products.length;
    final purchasesCount = purchasesState.purchases.length;
    final itemsCount = purchasesState.purchases.fold<int>(
      0,
      (sum, purchase) => sum + purchase.items.length,
    );

    return Stack(
      children: [
        Column(
          children: [
            _SettingsHeader(userName: currentUser?.name),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _feedbackMessage == null
                        ? const SizedBox.shrink()
                        : Padding(
                            key: ValueKey<String>(_feedbackMessage!),
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _SettingsFeedback(
                              message: _feedbackMessage!,
                              isError: _feedbackIsError,
                            ),
                          ),
                  ),
                  if (currentUser != null) ...[
                    _CurrentUserCard(
                      name: currentUser.name,
                      email: currentUser.email,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _LocalStorageStatusCard(
                    categoriesCount: categoriesCount,
                    productsCount: productsCount,
                    purchasesCount: purchasesCount,
                    itemsCount: itemsCount,
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: _SettingsTexts.localDataSection,
                    child: Column(
                      children: [
                        _SettingsActionCard(
                          icon: Icons.restart_alt_rounded,
                          title: _SettingsTexts.restoreCategoriesTitle,
                          subtitle: _SettingsTexts.restoreCategoriesSubtitle,
                          foregroundColor: AppColors.primary,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.10,
                          ),
                          onTap: () {
                            _openConfirmation(
                              _SettingsConfirmationAction
                                  .restoreDefaultCategories,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _SettingsActionCard(
                          icon: Icons.delete_forever_outlined,
                          title: _SettingsTexts.clearAllDataTitle,
                          subtitle: _SettingsTexts.clearAllDataSubtitle,
                          foregroundColor: AppColors.danger,
                          backgroundColor: AppColors.danger.withValues(
                            alpha: 0.10,
                          ),
                          onTap: () {
                            _openConfirmation(
                              _SettingsConfirmationAction.clearAllData,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: _SettingsTexts.accountSection,
                    child: Column(
                      children: [
                        _SettingsActionCard(
                          icon: Icons.logout_rounded,
                          title: _SettingsTexts.logoutTitle,
                          subtitle: _SettingsTexts.logoutSubtitle,
                          foregroundColor: AppColors.danger,
                          backgroundColor: AppColors.danger.withValues(
                            alpha: 0.10,
                          ),
                          onTap: () {
                            _openConfirmation(
                              _SettingsConfirmationAction.logout,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SettingsSection(
                    title: _SettingsTexts.aboutSection,
                    child: Column(
                      children: [
                        _SettingsInfoTile(
                          icon: Icons.shopping_bag_outlined,
                          title: _SettingsTexts.appName,
                          subtitle: _SettingsTexts.appDescription,
                        ),
                        SizedBox(height: 10),
                        _SettingsInfoTile(
                          icon: Icons.storage_rounded,
                          title: _SettingsTexts.storageTitle,
                          subtitle: _SettingsTexts.storageDescription,
                        ),
                        SizedBox(height: 10),
                        _SettingsInfoTile(
                          icon: Icons.info_outline_rounded,
                          title: _SettingsTexts.versionTitle,
                          subtitle: _SettingsTexts.versionValue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_confirmationAction != null)
          _SettingsConfirmationOverlay(
            action: _confirmationAction!,
            isLoading: _isConfirmingAction,
            onCancel: _isConfirmingAction ? null : _closeConfirmation,
            onConfirm: _isConfirmingAction ? null : _confirmAction,
          ),
      ],
    );
  }

  void _openConfirmation(_SettingsConfirmationAction action) {
    setState(() {
      _confirmationAction = action;
      _isConfirmingAction = false;
    });
  }

  void _closeConfirmation() {
    setState(() {
      _confirmationAction = null;
      _isConfirmingAction = false;
    });
  }

  Future<void> _confirmAction() async {
    final action = _confirmationAction;

    if (action == null || _isConfirmingAction) {
      return;
    }

    setState(() {
      _isConfirmingAction = true;
    });

    switch (action) {
      case _SettingsConfirmationAction.restoreDefaultCategories:
        ref.read(productsProvider.notifier).restoreDefaultCategories();

        if (!mounted) {
          return;
        }

        setState(() {
          _confirmationAction = null;
          _isConfirmingAction = false;
        });

        _showFeedback(message: _SettingsTexts.restoreSuccess, isError: false);
        break;

      case _SettingsConfirmationAction.clearAllData:
        ref.read(purchasesProvider.notifier).clearAllPurchases();
        ref.read(productsProvider.notifier).resetProductsAndCategories();

        if (!mounted) {
          return;
        }

        setState(() {
          _confirmationAction = null;
          _isConfirmingAction = false;
        });

        _showFeedback(message: _SettingsTexts.clearAllSuccess, isError: false);
        break;

      case _SettingsConfirmationAction.logout:
        await ref.read(authProvider.notifier).logout();

        if (!mounted) {
          return;
        }

        setState(() {
          _confirmationAction = null;
          _isConfirmingAction = false;
        });
        break;
    }
  }

  void _showFeedback({required String message, required bool isError}) {
    _feedbackTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });

    _feedbackTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedbackMessage = null;
        _feedbackIsError = false;
      });
    });
  }
}

class _SettingsHeader extends StatelessWidget {
  final String? userName;

  const _SettingsHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    final subtitle = userName == null
        ? _SettingsTexts.defaultSubtitle
        : 'Olá, $userName. Gerencie sua conta e seus dados locais.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _SettingsTexts.title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CurrentUserCard extends StatelessWidget {
  final String name;
  final String email;

  const _CurrentUserCard({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  _SettingsTexts.userConnected,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalStorageStatusCard extends StatelessWidget {
  final int categoriesCount;
  final int productsCount;
  final int purchasesCount;
  final int itemsCount;

  const _LocalStorageStatusCard({
    required this.categoriesCount,
    required this.productsCount,
    required this.purchasesCount,
    required this.itemsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.cloud_done_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _SettingsTexts.localDataTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            _SettingsTexts.localDataSubtitle,
            softWrap: true,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StorageChip(label: 'Categorias', value: categoriesCount),
              _StorageChip(label: 'Produtos', value: productsCount),
              _StorageChip(label: 'Compras', value: purchasesCount),
              _StorageChip(label: 'Itens', value: itemsCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageChip extends StatelessWidget {
  final String label;
  final int value;

  const _StorageChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _SettingsActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _SettingsActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: foregroundColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsFeedback extends StatelessWidget {
  final String message;
  final bool isError;

  const _SettingsFeedback({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsConfirmationOverlay extends StatelessWidget {
  final _SettingsConfirmationAction action;
  final bool isLoading;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const _SettingsConfirmationOverlay({
    required this.action,
    required this.isLoading,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isClearAllData = action == _SettingsConfirmationAction.clearAllData;
    final isLogout = action == _SettingsConfirmationAction.logout;

    final title = switch (action) {
      _SettingsConfirmationAction.clearAllData =>
        _SettingsTexts.clearDialogTitle,
      _SettingsConfirmationAction.restoreDefaultCategories =>
        _SettingsTexts.restoreDialogTitle,
      _SettingsConfirmationAction.logout => _SettingsTexts.logoutDialogTitle,
    };

    final message = switch (action) {
      _SettingsConfirmationAction.clearAllData =>
        _SettingsTexts.clearDialogMessage,
      _SettingsConfirmationAction.restoreDefaultCategories =>
        _SettingsTexts.restoreDialogMessage,
      _SettingsConfirmationAction.logout => _SettingsTexts.logoutDialogMessage,
    };

    final confirmLabel = switch (action) {
      _SettingsConfirmationAction.clearAllData =>
        _SettingsTexts.clearDialogConfirm,
      _SettingsConfirmationAction.restoreDefaultCategories =>
        _SettingsTexts.restoreDialogConfirm,
      _SettingsConfirmationAction.logout => _SettingsTexts.logoutDialogConfirm,
    };

    final color = isClearAllData || isLogout
        ? AppColors.danger
        : AppColors.primary;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.34),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isLogout
                            ? Icons.logout_rounded
                            : isClearAllData
                            ? Icons.delete_forever_outlined
                            : Icons.restart_alt_rounded,
                        color: color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancel,
                            child: const Text(_SettingsTexts.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: color,
                            ),
                            onPressed: onConfirm,
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    confirmLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ),
                      ],
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

enum _SettingsConfirmationAction {
  clearAllData,
  restoreDefaultCategories,
  logout,
}
