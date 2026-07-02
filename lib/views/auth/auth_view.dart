import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isRegisterMode = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isSubmitting = false;

  String? _feedbackMessage;
  bool _feedbackIsError = false;
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    FocusScope.of(context).unfocus();

    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _feedbackMessage = null;
      _feedbackIsError = false;
      _showPassword = false;
      _showConfirmPassword = false;
    });
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

    final authViewModel = ref.read(authProvider.notifier);

    final errorMessage = _isRegisterMode
        ? await authViewModel.register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          )
        : await authViewModel.login(
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (errorMessage != null) {
      _showLocalMessage(errorMessage, isError: true);
      return;
    }

    if (_isRegisterMode) {
      setState(() {
        _isRegisterMode = false;
        _passwordController.clear();
        _confirmPasswordController.clear();
        _showPassword = false;
        _showConfirmPassword = false;
      });

      _showLocalMessage('Conta criada com sucesso. Faça login para continuar.');
      return;
    }

    _showLocalMessage('Login realizado com sucesso.');
  }

  @override
  Widget build(BuildContext context) {
    final title = _isRegisterMode ? 'Criar conta' : 'Entrar na conta';

    final subtitle = _isRegisterMode
        ? 'Cadastre-se para organizar suas compras mensais.'
        : 'Acesse sua conta para organizar suas compras.';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AuthTopHeader(
              title: title,
              subtitle: subtitle,
              isRegisterMode: _isRegisterMode,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _feedbackMessage == null
                          ? const SizedBox.shrink()
                          : _AuthFeedbackMessage(
                              key: ValueKey<String>(_feedbackMessage!),
                              message: _feedbackMessage!,
                              isError: _feedbackIsError,
                            ),
                    ),
                    if (_feedbackMessage != null) const SizedBox(height: 14),
                    if (!_isRegisterMode) ...[
                      const _AuthBenefitsCard(),
                      const SizedBox(height: 16),
                    ],
                    _AuthFormPanel(
                      formKey: _formKey,
                      isRegisterMode: _isRegisterMode,
                      isSubmitting: _isSubmitting,
                      showPassword: _showPassword,
                      showConfirmPassword: _showConfirmPassword,
                      nameController: _nameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      onTogglePassword: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                      onToggleConfirmPassword: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: 16),
                    _AuthModeSwitcher(
                      isRegisterMode: _isRegisterMode,
                      onTap: _toggleMode,
                    ),
                    const SizedBox(height: 18),
                    const _AuthAccountNote(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTopHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isRegisterMode;

  const _AuthTopHeader({
    required this.title,
    required this.subtitle,
    required this.isRegisterMode,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primaryColor(context);
    final primaryDarkColor = AppColors.primaryDarkColor(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(
              alpha: AppColors.isDark(context) ? 0.18 : 0.24,
            ),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  isRegisterMode
                      ? Icons.person_add_alt_1_rounded
                      : Icons.shopping_cart_checkout_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  isRegisterMode ? 'Novo cadastro' : 'Acesso seguro',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Feira Mensal',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFormPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isRegisterMode;
  final bool isSubmitting;
  final bool showPassword;
  final bool showConfirmPassword;

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;

  const _AuthFormPanel({
    required this.formKey,
    required this.isRegisterMode,
    required this.isSubmitting,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primaryColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.24 : 0.045,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isRegisterMode ? 'Dados do cadastro' : 'Dados de acesso',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimaryColor(context),
                    ),
                  ),
                ),
                Icon(
                  isRegisterMode
                      ? Icons.assignment_ind_outlined
                      : Icons.lock_outline_rounded,
                  size: 21,
                  color: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (isRegisterMode) ...[
              _authTextField(
                context,
                controller: nameController,
                label: 'Nome *',
                hint: 'Seu nome',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ ]')),
                  LengthLimitingTextInputFormatter(40),
                ],
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Informe seu nome';
                  }

                  if (text.length < 2) {
                    return 'Informe pelo menos 2 caracteres';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 13),
            ],
            _authTextField(
              context,
              controller: emailController,
              label: 'E-mail *',
              hint: 'email@dominio.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                LengthLimitingTextInputFormatter(80),
              ],
              validator: (value) {
                final text = value?.trim() ?? '';

                if (text.isEmpty) {
                  return 'Informe seu e-mail';
                }

                final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

                if (!emailRegex.hasMatch(text)) {
                  return 'Informe um e-mail válido';
                }

                return null;
              },
            ),
            const SizedBox(height: 13),
            _authTextField(
              context,
              controller: passwordController,
              label: 'Senha *',
              hint: 'Mínimo 6 caracteres',
              icon: Icons.lock_outline_rounded,
              keyboardType: TextInputType.visiblePassword,
              obscureText: !showPassword,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                LengthLimitingTextInputFormatter(20),
              ],
              suffixIcon: IconButton(
                tooltip: showPassword ? 'Ocultar senha' : 'Mostrar senha',
                onPressed: onTogglePassword,
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';

                if (text.isEmpty) {
                  return 'Informe sua senha';
                }

                if (text.length < 6) {
                  return 'A senha deve ter pelo menos 6 caracteres';
                }

                return null;
              },
            ),
            if (isRegisterMode) ...[
              const SizedBox(height: 13),
              _authTextField(
                context,
                controller: confirmPasswordController,
                label: 'Confirmar senha *',
                hint: 'Repita sua senha',
                icon: Icons.lock_reset_rounded,
                keyboardType: TextInputType.visiblePassword,
                obscureText: !showConfirmPassword,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  LengthLimitingTextInputFormatter(20),
                ],
                suffixIcon: IconButton(
                  tooltip: showConfirmPassword
                      ? 'Ocultar senha'
                      : 'Mostrar senha',
                  onPressed: onToggleConfirmPassword,
                  icon: Icon(
                    showConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Confirme sua senha';
                  }

                  if (text != passwordController.text.trim()) {
                    return 'As senhas não conferem';
                  }

                  return null;
                },
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox.shrink()
                    : Icon(
                        isRegisterMode
                            ? Icons.person_add_alt_1_rounded
                            : Icons.login_rounded,
                        size: 19,
                      ),
                label: isSubmitting
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Text(isRegisterMode ? 'Cadastrar' : 'Entrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _authTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String? value) validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    final primaryColor = AppColors.primaryColor(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      style: TextStyle(
        color: AppColors.textPrimaryColor(context),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.textSecondaryColor(context)),
        hintStyle: TextStyle(
          color: AppColors.textSecondaryColor(context).withValues(alpha: 0.75),
        ),
        prefixIcon: Icon(icon),
        prefixIconColor: AppColors.textSecondaryColor(context),
        suffixIcon: suffixIcon,
        suffixIconColor: AppColors.textSecondaryColor(context),
        filled: true,
        isDense: true,
        fillColor: AppColors.surfaceSoftColor(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(17)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(color: AppColors.borderColor(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(color: primaryColor, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      validator: validator,
    );
  }
}

class _AuthFeedbackMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _AuthFeedbackMessage({
    super.key,
    required this.message,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.18 : 0.12),
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
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthModeSwitcher extends StatelessWidget {
  final bool isRegisterMode;
  final VoidCallback onTap;

  const _AuthModeSwitcher({required this.isRegisterMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primaryColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Row(
        children: [
          Icon(
            isRegisterMode
                ? Icons.login_rounded
                : Icons.person_add_alt_1_rounded,
            color: primaryColor,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRegisterMode
                  ? 'Já possui uma conta cadastrada?'
                  : 'Ainda não possui uma conta?',
              style: TextStyle(
                color: AppColors.textSecondaryColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              isRegisterMode ? 'Entrar' : 'Criar cadastro',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBenefitsCard extends StatelessWidget {
  const _AuthBenefitsCard();

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primaryColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppColors.isDark(context) ? 0.20 : 0.035,
            ),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'O que o app oferece?',
                  style: TextStyle(
                    color: AppColors.textPrimaryColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const _BenefitItem(
            icon: Icons.shopping_basket_outlined,
            title: 'Produtos organizados',
            subtitle: 'Cadastre itens, marcas, categorias e unidades.',
          ),
          const SizedBox(height: 10),
          const _BenefitItem(
            icon: Icons.receipt_long_outlined,
            title: 'Compras mensais',
            subtitle: 'Registre suas feiras e acompanhe cada item.',
          ),
          const SizedBox(height: 10),
          const _BenefitItem(
            icon: Icons.bar_chart_rounded,
            title: 'Relatórios inteligentes',
            subtitle: 'Veja gastos por período, categoria e produto.',
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primaryColor(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primarySoftBackground(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimaryColor(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondaryColor(context),
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthAccountNote extends StatelessWidget {
  const _AuthAccountNote();

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primaryColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: primaryColor.withValues(
          alpha: AppColors.isDark(context) ? 0.14 : 0.06,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryColor.withValues(
            alpha: AppColors.isDark(context) ? 0.28 : 0.14,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security_rounded, color: primaryColor, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Seus dados ficam vinculados à sua conta.',
              style: TextStyle(
                color: AppColors.textSecondaryColor(context),
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
