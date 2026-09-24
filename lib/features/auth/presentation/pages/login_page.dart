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
  bool _isSubmitting = false;
  bool _emailPrefillLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLastEmail();
  }

  Future<void> _loadLastEmail() async {
    try {
      final lastEmail = await ref.read(authRepositoryProvider).readLastEmail();
      if (!mounted || _emailPrefillLoaded) return;
      _emailPrefillLoaded = true;
      if (lastEmail != null && lastEmail.trim().isNotEmpty) {
        _emailController.text = lastEmail.trim();
      }
    } catch (_) {
      // Prefill is best-effort; login remains fully usable without it.
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || ref.read(authProvider).isLoading) return;

    if (!_formKey.currentState!.validate()) {
      if (!_isValidEmail(_emailController.text)) {
        _emailFocusNode.requestFocus();
      } else {
        _passwordFocusNode.requestFocus();
      }
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSubmitting = true);
    try {
      final email = _emailController.text.trim();
      await ref
          .read(authProvider.notifier)
          .login(email: email, password: _passwordController.text);
      if (!mounted || ref.read(authProvider).hasError) return;
      if (email.isNotEmpty) {
        await ref.read(authRepositoryProvider).saveLastEmail(email);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _isValidEmail(String? value) {
    final email = value?.trim() ?? '';
    return email.isNotEmpty && email.contains('@') && email.contains('.');
  }

  bool _isSessionExpired(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.queryParameters['reason'] ==
          'session_expired';
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final sessionExpired = _isSessionExpired(context);
    final isSubmitting = _isSubmitting || auth.isLoading;
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
            final isTablet = constraints.maxWidth >= 900;
            // Virtual keyboard in landscape collapses height below ~520dp.
            // Hiding the brand panel there keeps the CTA scroll-reachable
            // instead of forcing a RenderFlex overflow.
            final brandVisible = isTablet && constraints.maxHeight >= 520;
            final form = _LoginFormArea(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              emailFocusNode: _emailFocusNode,
              passwordFocusNode: _passwordFocusNode,
              obscurePassword: _obscurePassword,
              isSubmitting: isSubmitting,
              sessionExpired: sessionExpired,
              errorMessage: errorMessage,
              showBrandHeader: !brandVisible,
              showTrustLine: !brandVisible,
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onSubmit: _submit,
            );

            if (brandVisible) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(flex: 5, child: _LoginBrandPanel()),
                  Expanded(flex: 6, child: form),
                ],
              );
            }

            return form;
          },
        ),
      ),
    );
  }
}

class _LoginFormArea extends StatelessWidget {
  const _LoginFormArea({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.sessionExpired,
    required this.errorMessage,
    required this.showBrandHeader,
    required this.showTrustLine,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final bool isSubmitting;
  final bool sessionExpired;
  final String? errorMessage;
  final bool showBrandHeader;
  final bool showTrustLine;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final constraints = BoxConstraints.loose(MediaQuery.sizeOf(context));
    final horizontalPadding = constraints.maxWidth >= 600
        ? AppSpacing.xxxl
        : AppSpacing.xxl;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.xxxl,
        horizontalPadding,
        AppSpacing.xxl,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: AutofillGroup(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showBrandHeader) ...[
                    const _LoginBrandHeader(),
                    const SizedBox(height: AppSpacing.section),
                  ],
                  Text(
                    'Masuk untuk mulai berjualan.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Akses katalog, keranjang, dan transaksi tunai dari akun kasir Anda.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  TextFormField(
                    controller: emailController,
                    focusNode: emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: 'nama@contoh.com',
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
                    onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: 'Masukkan password Anda',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: onTogglePassword,
                        tooltip: obscurePassword
                            ? 'Tampilkan password'
                            : 'Sembunyikan password',
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Password wajib diisi.'
                        : null,
                    onFieldSubmitted: (_) {
                      if (!isSubmitting) onSubmit();
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
                      message: errorMessage!,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  FilledButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSubmitting) ...[
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: Text(
                            isSubmitting
                                ? 'Memproses masuk...'
                                : 'Masuk ke akun',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showTrustLine) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    const _LoginTrustLine(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isValidEmail(String? value) {
    final email = value?.trim() ?? '';
    return email.isNotEmpty && email.contains('@') && email.contains('.');
  }
}

class _LoginBrandHeader extends StatelessWidget {
  const _LoginBrandHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const _LoginBrandMark(size: 48),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Go-Barokah', style: Theme.of(context).textTheme.titleLarge),
            Text('Area kasir', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.cream,
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.huge),
      child: _LoginBrandPanelContent(),
    ),
  );
}

class _LoginBrandPanelContent extends StatelessWidget {
  const _LoginBrandPanelContent();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LoginBrandMark(size: 56),
        const Expanded(child: SizedBox.shrink()),
        Text(
          'Go-Barokah',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(color: AppColors.forestGreen),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Katalog, keranjang, dan transaksi tunai dalam satu tempat.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textBody),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        const _LoginTrustLine(),
        const Expanded(child: SizedBox.shrink()),
        Text(
          'Akses khusus untuk akun cashier UD. Barokah.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textBody),
        ),
      ],
    ),
  );
}

class _LoginTrustLine extends StatelessWidget {
  const _LoginTrustLine();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Akses untuk operasional kasir Go-Barokah',
    child: Row(
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: 18,
          color: AppColors.warmBrown,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Siap membantu operasional kasir Anda.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}

class _LoginBrandMark extends StatelessWidget {
  const _LoginBrandMark({this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Logo Go-Barokah',
    image: true,
    child: Container(
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
