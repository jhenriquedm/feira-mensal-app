import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/purchase_model.dart';
import '../../viewmodels/purchases_viewmodel.dart';
import 'purchase_details_panel.dart';

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);

final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

class _PurchaseFormResult {
  final String message;
  final String? purchaseId;
  final String name;
  final String market;
  final DateTime date;
  final PurchaseType type;
  final String notes;

  const _PurchaseFormResult({
    required this.message,
    required this.purchaseId,
    required this.name,
    required this.market,
    required this.date,
    required this.type,
    required this.notes,
  });
}

class PurchasesView extends ConsumerStatefulWidget {
  const PurchasesView({super.key});

  @override
  ConsumerState<PurchasesView> createState() => _PurchasesViewState();
}

class _PurchasesViewState extends ConsumerState<PurchasesView> {
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  Timer? _feedbackTimer;

  bool _isPurchaseFormVisible = false;
  PurchaseModel? _purchaseBeingEdited;
  PurchaseModel? _purchasePendingDelete;
  String? _selectedPurchaseId;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  List<PurchaseModel> _sortPurchases(List<PurchaseModel> purchases) {
    final sortedPurchases = [...purchases];

    sortedPurchases.sort((first, second) {
      return second.date.compareTo(first.date);
    });

    return sortedPurchases;
  }

  void _showLocalMessage(String message, {bool isError = false}) {
    _feedbackTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });

    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _feedbackMessage = null;
        _feedbackIsError = false;
      });
    });
  }

  void _openPurchaseDetails(PurchaseModel purchase) {
    setState(() {
      _selectedPurchaseId = purchase.id;
      _isPurchaseFormVisible = false;
      _purchaseBeingEdited = null;
      _purchasePendingDelete = null;
    });
  }

  void _closePurchaseDetails() {
    setState(() {
      _selectedPurchaseId = null;
    });
  }

  void _openCreatePurchaseForm() {
    setState(() {
      _purchaseBeingEdited = null;
      _purchasePendingDelete = null;
      _selectedPurchaseId = null;
      _isPurchaseFormVisible = true;
    });
  }

  void _openEditPurchaseForm(PurchaseModel purchase) {
    setState(() {
      _purchaseBeingEdited = purchase;
      _purchasePendingDelete = null;
      _selectedPurchaseId = null;
      _isPurchaseFormVisible = true;
    });
  }

  void _closePurchaseForm() {
    setState(() {
      _isPurchaseFormVisible = false;
      _purchaseBeingEdited = null;
    });
  }

  Future<void> _savePurchase(_PurchaseFormResult result) async {
    setState(() {
      _isPurchaseFormVisible = false;
      _purchaseBeingEdited = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (!mounted) {
      return;
    }

    final viewModel = ref.read(purchasesProvider.notifier);

    if (result.purchaseId == null) {
      viewModel.addPurchase(
        name: result.name,
        market: result.market,
        date: result.date,
        type: result.type,
        notes: result.notes,
      );
    } else {
      viewModel.updatePurchase(
        id: result.purchaseId!,
        name: result.name,
        market: result.market,
        date: result.date,
        type: result.type,
        notes: result.notes,
      );
    }

    _showLocalMessage(result.message);
  }

  void _requestDeletePurchase(PurchaseModel purchase) {
    final viewModel = ref.read(purchasesProvider.notifier);

    if (!viewModel.canDeletePurchase(purchase.id)) {
      _showLocalMessage(
        'A compra não pode ser excluída porque possui itens.',
        isError: true,
      );
      return;
    }

    setState(() {
      _purchasePendingDelete = purchase;
      _isPurchaseFormVisible = false;
      _purchaseBeingEdited = null;
      _selectedPurchaseId = null;
    });
  }

  Future<void> _confirmDeletePurchase() async {
    final purchase = _purchasePendingDelete;

    if (purchase == null) {
      return;
    }

    setState(() {
      _purchasePendingDelete = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 80));

    if (!mounted) {
      return;
    }

    ref.read(purchasesProvider.notifier).deletePurchase(purchase.id);

    _showLocalMessage('Compra excluída com sucesso.');
  }

  void _cancelDeletePurchase() {
    setState(() {
      _purchasePendingDelete = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchasesProvider);
    final purchases = _sortPurchases(state.purchases);
    final viewModel = ref.read(purchasesProvider.notifier);

    final hasOverlay =
        _isPurchaseFormVisible ||
        _purchasePendingDelete != null ||
        _selectedPurchaseId != null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _PurchasesHeader(state: state),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _feedbackMessage == null
                      ? const SizedBox.shrink()
                      : _LocalFeedbackMessage(
                          key: ValueKey<String>(_feedbackMessage!),
                          message: _feedbackMessage!,
                          isError: _feedbackIsError,
                        ),
                ),
                Expanded(
                  child: purchases.isEmpty
                      ? const _EmptyPurchasesState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                          itemCount: purchases.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (context, index) {
                            final purchase = purchases[index];

                            return _PurchaseCard(
                              purchase: purchase,
                              onTap: () {
                                _openPurchaseDetails(purchase);
                              },
                              onEdit: () {
                                _openEditPurchaseForm(purchase);
                              },
                              onDelete: () {
                                _requestDeletePurchase(purchase);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
            if (_isPurchaseFormVisible)
              _ScreenOverlay(
                child: _PurchaseFormPanel(
                  viewModel: viewModel,
                  purchase: _purchaseBeingEdited,
                  onCancel: _closePurchaseForm,
                  onSubmit: _savePurchase,
                ),
              ),
            if (_purchasePendingDelete != null)
              _ScreenOverlay(
                child: _DeletePurchasePanel(
                  purchase: _purchasePendingDelete!,
                  onCancel: _cancelDeletePurchase,
                  onConfirm: _confirmDeletePurchase,
                ),
              ),
            if (_selectedPurchaseId != null)
              _ScreenOverlay(
                child: PurchaseDetailsPanel(
                  purchaseId: _selectedPurchaseId!,
                  onClose: _closePurchaseDetails,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: hasOverlay
          ? null
          : FloatingActionButton(
              tooltip: 'Adicionar compra',
              onPressed: _openCreatePurchaseForm,
              child: const Icon(Icons.add),
            ),
    );
  }
}

class _PurchasesHeader extends StatelessWidget {
  final PurchasesState state;

  const _PurchasesHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final inProgressCount = state.purchases
        .where((purchase) => purchase.status == PurchaseStatus.inProgress)
        .length;

    final completedCount = state.purchases
        .where((purchase) => purchase.status == PurchaseStatus.completed)
        .length;

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
            'Compras',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Organize e acompanhe suas feiras.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderSummaryCard(
                  icon: Icons.pending_actions_rounded,
                  title: 'Em andamento',
                  value: inProgressCount.toString(),
                  foregroundColor: AppColors.warning,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.11),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderSummaryCard(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Finalizadas',
                  value: completedCount.toString(),
                  foregroundColor: AppColors.success,
                  backgroundColor: AppColors.success.withValues(alpha: 0.11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderSummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color foregroundColor;
  final Color backgroundColor;

  const _HeaderSummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: foregroundColor),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 11,
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

class _LocalFeedbackMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _LocalFeedbackMessage({
    super.key,
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.success;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  final PurchaseModel purchase;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PurchaseCard({
    required this.purchase,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = purchase.isCompleted;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 16, 10, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success.withValues(alpha: 0.11)
                          : AppColors.primary.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_outline_rounded
                          : Icons.shopping_cart_checkout_rounded,
                      color: isCompleted
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          purchase.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                purchase.market,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Opções',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      }

                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 10),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: AppColors.danger,
                              ),
                              SizedBox(width: 10),
                              Text('Excluir'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InformationChip(
                    icon: Icons.calendar_today_outlined,
                    label: _dateFormatter.format(purchase.date),
                  ),
                  _InformationChip(
                    icon: Icons.category_outlined,
                    label: purchase.type.label,
                  ),
                  _InformationChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${purchase.distinctItemsCount} itens',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 13),
              Row(
                children: [
                  _StatusChip(isCompleted: isCompleted),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _currencyFormatter.format(purchase.total),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Toque para ver detalhes',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InformationChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isCompleted;

  const _StatusChip({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final color = isCompleted ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        isCompleted ? 'Finalizada' : 'Em andamento',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyPurchasesState extends StatelessWidget {
  const _EmptyPurchasesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(27),
              ),
              child: const Icon(
                Icons.shopping_cart_checkout_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nenhuma compra cadastrada',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie sua primeira compra para começar a registrar os itens da feira.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenOverlay extends StatelessWidget {
  final Widget child;

  const _ScreenOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.48),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PurchaseFormPanel extends StatefulWidget {
  final PurchasesViewModel viewModel;
  final PurchaseModel? purchase;
  final VoidCallback onCancel;
  final void Function(_PurchaseFormResult result) onSubmit;

  const _PurchaseFormPanel({
    required this.viewModel,
    required this.purchase,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<_PurchaseFormPanel> createState() => _PurchaseFormPanelState();
}

class _PurchaseFormPanelState extends State<_PurchaseFormPanel> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _marketController;
  late final TextEditingController _notesController;
  late final TextEditingController _dateController;

  late DateTime _selectedDate;
  PurchaseType? _selectedType;
  String? _duplicateError;
  bool _showCalendar = false;

  DateTime get _todayOnly {
    final today = DateTime.now();
    return DateTime(today.year, today.month, today.day);
  }

  @override
  void initState() {
    super.initState();

    final today = _todayOnly;

    _nameController = TextEditingController(text: widget.purchase?.name ?? '');

    _marketController = TextEditingController(
      text: widget.purchase?.market ?? '',
    );

    _notesController = TextEditingController(
      text: widget.purchase?.notes ?? '',
    );

    _selectedDate = widget.purchase?.date ?? today;

    if (_selectedDate.isAfter(today)) {
      _selectedDate = today;
    }

    _dateController = TextEditingController(
      text: _dateFormatter.format(_selectedDate),
    );

    _selectedType = widget.purchase?.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _marketController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _clearDuplicateError() {
    if (_duplicateError == null) {
      return;
    }

    setState(() {
      _duplicateError = null;
    });
  }

  void _toggleCalendar() {
    FocusScope.of(context).unfocus();

    setState(() {
      _showCalendar = !_showCalendar;
      _duplicateError = null;
    });
  }

  void _selectDate(DateTime date) {
    final safeDate = date.isAfter(_todayOnly) ? _todayOnly : date;

    setState(() {
      _selectedDate = safeDate;
      _dateController.text = _dateFormatter.format(safeDate);
      _showCalendar = false;
      _duplicateError = null;
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate.isAfter(_todayOnly)) {
      setState(() {
        _duplicateError = 'Não é permitido cadastrar compra com data futura.';
      });
      return;
    }

    final alreadyExists = widget.viewModel.purchaseAlreadyExists(
      name: _nameController.text,
      market: _marketController.text,
      date: _selectedDate,
      ignorePurchaseId: widget.purchase?.id,
    );

    if (alreadyExists) {
      setState(() {
        _duplicateError = 'Já existe uma compra com este nome, mercado e data.';
      });
      return;
    }

    widget.onSubmit(
      _PurchaseFormResult(
        purchaseId: widget.purchase?.id,
        name: _nameController.text.trim(),
        market: _marketController.text.trim(),
        date: _selectedDate,
        type: _selectedType!,
        notes: _notesController.text.trim(),
        message: widget.purchase == null
            ? 'Compra cadastrada com sucesso.'
            : 'Compra atualizada com sucesso.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseTypes = [...PurchaseType.values]
      ..sort((first, second) {
        return first.label.compareTo(second.label);
      });

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 342),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.purchase == null ? 'Nova compra' : 'Editar compra',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _purchaseTextField(
                controller: _nameController,
                label: 'Nome da compra *',
                hint: 'Ex: Feira Junho 2026',
                maxLength: 40,
                requiredMessage: 'Informe o nome da compra',
                onChanged: (_) {
                  _clearDuplicateError();
                },
              ),
              const SizedBox(height: 11),
              _purchaseTextField(
                controller: _marketController,
                label: 'Mercado *',
                hint: 'Ex: Assaí Atacadista',
                maxLength: 40,
                requiredMessage: 'Informe o mercado',
                onChanged: (_) {
                  _clearDuplicateError();
                },
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: _purchaseInputDecoration('Data da compra *')
                    .copyWith(
                      prefixIcon: const Icon(Icons.calendar_month_outlined),
                      suffixIcon: Icon(
                        _showCalendar
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.arrow_drop_down_rounded,
                      ),
                    ),
                onTap: _toggleCalendar,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe a data da compra';
                  }

                  return null;
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: !_showCalendar
                    ? const SizedBox.shrink()
                    : _InlineCalendar(
                        key: const ValueKey<String>('calendar'),
                        selectedDate: _selectedDate,
                        lastAllowedDate: _todayOnly,
                        onDateSelected: _selectDate,
                      ),
              ),
              const SizedBox(height: 11),
              DropdownButtonFormField<PurchaseType>(
                initialValue: _selectedType,
                isExpanded: true,
                menuMaxHeight: 240,
                borderRadius: BorderRadius.circular(18),
                dropdownColor: AppColors.surface,
                decoration: _purchaseInputDecoration('Tipo da compra *'),
                items: purchaseTypes.map((type) {
                  return DropdownMenuItem<PurchaseType>(
                    value: type,
                    child: Text(type.label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                    _duplicateError = null;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecione o tipo da compra';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: _notesController,
                maxLength: 150,
                maxLines: 2,
                minLines: 2,
                inputFormatters: [LengthLimitingTextInputFormatter(150)],
                decoration: _purchaseInputDecoration(
                  'Observação',
                ).copyWith(hintText: 'Informação opcional'),
              ),
              if (_duplicateError != null) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 19,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _duplicateError!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime lastAllowedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _InlineCalendar({
    super.key,
    required this.selectedDate,
    required this.lastAllowedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final safeSelectedDate = selectedDate.isAfter(lastAllowedDate)
        ? lastAllowedDate
        : selectedDate;

    return Container(
      width: double.infinity,
      height: 304,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: CalendarDatePicker(
          initialDate: safeSelectedDate,
          firstDate: DateTime(2000),
          lastDate: lastAllowedDate,
          onDateChanged: onDateSelected,
        ),
      ),
    );
  }
}

class _DeletePurchasePanel extends StatelessWidget {
  final PurchaseModel purchase;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _DeletePurchasePanel({
    required this.purchase,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 330),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
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
                color: AppColors.danger.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Excluir compra?',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'A compra "${purchase.name}" será removida permanentemente.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onConfirm,
                    child: const Text('Excluir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _purchaseTextField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required int maxLength,
  required String requiredMessage,
  ValueChanged<String>? onChanged,
}) {
  return TextFormField(
    controller: controller,
    maxLength: maxLength,
    textCapitalization: TextCapitalization.words,
    onChanged: onChanged,
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ0-9 ]')),
      LengthLimitingTextInputFormatter(maxLength),
    ],
    decoration: _purchaseInputDecoration(
      label,
    ).copyWith(hintText: hint, counterText: ''),
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return requiredMessage;
      }

      if (value.trim().length < 2) {
        return 'Informe pelo menos 2 caracteres';
      }

      return null;
    },
  );
}

InputDecoration _purchaseInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    isDense: true,
    fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
    ),
  );
}
