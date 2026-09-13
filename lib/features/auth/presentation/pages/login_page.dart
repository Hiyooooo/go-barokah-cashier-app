import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      if (!_isValidEmail(_emailController.text)) {
        _emailFocusNode.requestFocus();
      } else {
        _passwordFocusNode.requestFocus();
      }
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  bool _isValidEmail(String? value) {
    final email = value?.trim() ?? '';
    return email.isNotEmpty && email.contains('@') && email.contains('.');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final sessionExpired =
        GoRouterState.of(context).uri.queryParameters['reason'] ==
        'session_expired';
    final isLoading = auth.isLoading;
    final errorMessage = auth.hasError
        ? userFacingError(
            auth.error!,
            fallback: 'Email atau password tidak cocok.',
          )
        : null;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideTablet = constraints.maxWidth >= 900;
            if (isWideTablet) {
              return Row(
                children: [
                  const Expanded(child: _LoginBrandPanel()),
                  Expanded(
                    child: _buildFormArea(
                      context,
                      constraints,
                      isLoading: isLoading,
                      sessionExpired: sessionExpired,
                      errorMessage: errorMessage,
                    ),
                  ),
                ],
              );
            }

            return _buildFormArea(
              context,
              constraints,
              isLoading: isLoading,
              sessionExpired: sessionExpired,
              errorMessage: errorMessage,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormArea(
    BuildContext context,
    BoxConstraints constraints, {
    required bool isLoading,
    required bool sessionExpired,
    required String? errorMessage,
  }) {
    final horizontalPadding = constraints.maxWidth >= 600
        ? AppSpacing.xxxl
        : AppSpacing.xxl;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.xxxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (constraints.maxWidth < 900) ...[
                    const _LoginBrandHeader(),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                  Text(
                    'Mulai transaksi baru dengan cepat.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Masuk untuk melanjutkan ke katalog dan keranjang.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi.';
                      }
                      if (!_isValidEmail(value)) {
                        return 'Masukkan alamat email yang valid.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        tooltip: _obscurePassword
                            ? 'Tampilkan password'
                            : 'Sembunyikan password',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Password wajib diisi.'
                        : null,
                    onFieldSubmitted: (_) {
                      if (!isLoading) _submit();
                    },
                  ),
                  if (sessionExpired) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const _LoginMessage(
                      icon: Icons.info_outline,
                      message:
                          'Sesi Anda telah berakhir. Silakan masuk kembali.',
                      isWarning: true,
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _LoginMessage(
                      icon: Icons.error_outline,
                      message: errorMessage,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoading) ...[
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          isLoading ? 'Memproses masuk...' : 'Masuk ke akun',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Akses khusus cashier UD. Barokah.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
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

class _LoginBrandHeader extends StatelessWidget {
  const _LoginBrandHeader();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _LoginBrandMark(),
      SizedBox(width: AppSpacing.md),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Go-Barokah',
            style: TextStyle(
              color: AppColors.forestGreen,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Kasir',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    ],
  );
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.cream,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.huge),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LoginBrandMark(size: 64),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Go-Barokah',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Kasir yang ringkas untuk menjaga setiap transaksi tetap jelas.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textBody),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.forestGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Siap membantu proses penjualan Anda.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textBody),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LoginBrandMark extends StatelessWidget {
  const _LoginBrandMark({this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.forestGreen,
      borderRadius: BorderRadius.circular(size * 0.28),
    ),
    child: Icon(
      Icons.storefront_outlined,
      color: AppColors.surface,
      size: size * 0.52,
    ),
  );
}

class _LoginMessage extends StatelessWidget {
  const _LoginMessage({
    required this.icon,
    required this.message,
    this.isWarning = false,
  });

  final IconData icon;
  final String message;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final foreground = isWarning ? AppColors.warmBrown : AppColors.error;
    final background = isWarning
        ? AppColors.warningContainer
        : AppColors.errorContainer;

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
