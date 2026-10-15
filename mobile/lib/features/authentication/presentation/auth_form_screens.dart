import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../core/utils/l10n_ext.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/auth_controller.dart';

String? _requiredValidator(BuildContext context, String? v) =>
    (v == null || v.trim().isEmpty) ? context.l10n.validationRequired : null;

String? _emailValidator(BuildContext context, String? v) {
  final required = _requiredValidator(context, v);
  if (required != null) return required;
  final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return re.hasMatch(v!.trim()) ? null : context.l10n.validationEmail;
}

String? _passwordValidator(BuildContext context, String? v) {
  final required = _requiredValidator(context, v);
  if (required != null) return required;
  return v!.length >= 8 ? null : context.l10n.validationPasswordLength;
}

/// Shared scaffold for auth forms.
class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold(
      {required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter, AppSpacing.sm, AppSpacing.gutter, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: AppSpacing.xl),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
    if (!ok && mounted) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.message ?? context.l10n.errorGeneric)),
      );
    }
    // On success the router redirect takes the user to onboarding.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final fieldErrors = auth.error?.fieldErrors ?? const {};

    return _AuthScaffold(
      title: l10n.createAccount,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: l10n.fullName,
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) => _requiredValidator(context, v),
              errorText: fieldErrors['name']?.first,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.email,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) => _emailValidator(context, v),
              errorText: fieldErrors['email']?.first,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.password,
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) => _passwordValidator(context, v),
              errorText: fieldErrors['password']?.first,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: l10n.signUp,
              loading: auth.busy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.alreadyHaveAccount,
                    style: Theme.of(context).textTheme.bodyMedium),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(l10n.signIn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .login(email: _email.text, password: _password.text);
    if (!ok && mounted) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.message ?? context.l10n.errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);

    return _AuthScaffold(
      title: l10n.signIn,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: l10n.email,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) => _emailValidator(context, v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.password,
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (v) => _requiredValidator(context, v),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.forgotPassword),
                child: Text(l10n.forgotPassword),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: l10n.signIn,
              loading: auth.busy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.dontHaveAccount,
                    style: Theme.of(context).textTheme.bodyMedium),
                TextButton(
                  onPressed: () => context.go(AppRoutes.signUp),
                  child: Text(l10n.signUp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .forgotPassword(_email.text);
    if (mounted) setState(() => _sent = ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return _AuthScaffold(
      title: l10n.forgotPasswordTitle,
      subtitle: l10n.forgotPasswordSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_sent)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppRadius.cardRadius,
                ),
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read_outlined,
                        color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(l10n.resetLinkSent,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onPrimaryContainer)),
                    ),
                  ],
                ),
              ),
            AppTextField(
              label: l10n.email,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (v) => _emailValidator(context, v),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppPrimaryButton(
              label: l10n.sendResetLink,
              loading: auth.busy,
              onPressed: _submit,
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: Text(l10n.backToSignIn),
            ),
          ],
        ),
      ),
    );
  }
}
