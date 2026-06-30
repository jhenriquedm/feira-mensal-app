import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/purchases_viewmodel.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  _SettingsConfirmationAction? _confirmationAction;
  String? _feedbackMessage;
  bool _feedbackIsError = false;
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
                  if (_feedbackMessage != null) ...[
                    _SettingsFeedback(
                      message: _feedbackMessage!,
                      isError: _feedbackIsError,
                    ),
                    const SizedBox(height: 14),
                  ],
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
                    title: 'Gerenciar dados locais',
                    child: Column(
                      children: [
                        _SettingsActionCard(
                          icon: Icons.restart_alt_rounded,
                          title: 'Restaurar categorias padrão',
                          subtitle:
                              'Reativa e recria as categorias principais do app sem apagar produtos ou compras.',
                          foregroundColor: AppColors.primary,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.10,
                          ),
                          onTap: () {
                            setState(() {
                              _confirmationAction = _SettingsConfirmationAction
                                  .restoreDefaultCategories;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _SettingsActionCard(
                          icon: Icons.delete_forever_outlined,
                          title: 'Limpar todos os dados',
                          subtitle:
                              'Apaga produtos, compras, itens e relatórios deste usuário.',
                          foregroundColor: AppColors.danger,
                          backgroundColor: AppColors.danger.withValues(
                            alpha: 0.10,
                          ),
                          onTap: () {
                            setState(() {
                              _confirmationAction =
                                  _SettingsConfirmationAction.clearAllData;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Conta',
                    child: Column(
                      children: [
                        _SettingsActionCard(
                          icon: Icons.logout_rounded,
                          title: 'Sair da conta',
                          subtitle:
                              'Encerra a sessão atual e volta para a tela de login. Seus dados continuam salvos.',
                          foregroundColor: AppColors.danger,
                          backgroundColor: AppColors.danger.withValues(
                            alpha: 0.10,
                          ),
                          onTap: () {
                            setState(() {
                              _confirmationAction =
                                  _SettingsConfirmationAction.logout;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SettingsSection(
                    title: 'Sobre o app',
                    child: Column(
                      children: [
                        _SettingsInfoTile(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Feira Mensal',
                          subtitle:
                              'Controle de compras de mercado, produtos, categorias e relatórios.',
                        ),
                        SizedBox(height: 10),
                        _SettingsInfoTile(
                          icon: Icons.storage_rounded,
                          title: 'Armazenamento',
                          subtitle:
                              'Os dados estão sendo salvos localmente por usuário neste dispositivo.',
                        ),
                        SizedBox(height: 10),
                        _SettingsInfoTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Versão',
                          subtitle: '1.0.0',
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
            onCancel: () {
              setState(() {
                _confirmationAction = null;
              });
            },
            onConfirm: _confirmAction,
          ),
      ],
    );
  }

  Future<void> _confirmAction() async {
    final action = _confirmationAction;

    if (action == null) {
      return;
    }

    switch (action) {
      case _SettingsConfirmationAction.restoreDefaultCategories:
        ref.read(productsProvider.notifier).restoreDefaultCategories();

        _showFeedback(
          message: 'Categorias padrão restauradas com sucesso.',
          isError: false,
        );
        break;

      case _SettingsConfirmationAction.clearAllData:
        ref.read(purchasesProvider.notifier).clearAllPurchases();
        ref.read(productsProvider.notifier).resetProductsAndCategories();

        _showFeedback(
          message: 'Todos os dados deste usuário foram apagados com sucesso.',
          isError: false,
        );
        break;

      case _SettingsConfirmationAction.logout:
        await ref.read(authProvider.notifier).logout();
        break;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _confirmationAction = null;
    });
  }

  void _showFeedback({required String message, required bool isError}) {
    _feedbackTimer?.cancel();

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
        ? 'Gerencie dados locais, preferências e informações do app.'
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
            'Ajustes',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
                  'Usuário conectado',
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
                  'Dados salvos localmente',
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
            'As informações permanecem salvas para este usuário mesmo ao atualizar ou fechar o app.',
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
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
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
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
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _SettingsConfirmationOverlay({
    required this.action,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final isClearAllData = action == _SettingsConfirmationAction.clearAllData;
    final isLogout = action == _SettingsConfirmationAction.logout;

    final title = switch (action) {
      _SettingsConfirmationAction.clearAllData => 'Limpar todos os dados?',
      _SettingsConfirmationAction.restoreDefaultCategories =>
        'Restaurar categorias padrão?',
      _SettingsConfirmationAction.logout => 'Sair da conta?',
    };

    final message = switch (action) {
      _SettingsConfirmationAction.clearAllData =>
        'Essa ação apagará produtos, compras, itens e relatórios deste usuário. Essa ação não pode ser desfeita.',
      _SettingsConfirmationAction.restoreDefaultCategories =>
        'Essa ação recriará e reativará as categorias padrão do app, sem apagar produtos ou compras já cadastrados.',
      _SettingsConfirmationAction.logout =>
        'Sua sessão será encerrada e você voltará para a tela de login. Seus dados continuarão salvos.',
    };

    final confirmLabel = switch (action) {
      _SettingsConfirmationAction.clearAllData => 'Limpar dados',
      _SettingsConfirmationAction.restoreDefaultCategories => 'Restaurar',
      _SettingsConfirmationAction.logout => 'Sair',
    };

    final color = isClearAllData || isLogout
        ? AppColors.danger
        : AppColors.primary;

    return Container(
      color: Colors.black.withValues(alpha: 0.22),
      child: Center(
        child: Padding(
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
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: color),
                          onPressed: onConfirm,
                          child: Text(confirmLabel),
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
    );
  }
}

enum _SettingsConfirmationAction {
  clearAllData,
  restoreDefaultCategories,
  logout,
}
