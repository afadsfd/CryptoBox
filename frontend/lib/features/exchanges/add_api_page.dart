import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import 'add_api_provider.dart';

class AddApiPage extends ConsumerStatefulWidget {
  final String exchangeId;

  const AddApiPage({super.key, required this.exchangeId});

  @override
  ConsumerState<AddApiPage> createState() => _AddApiPageState();
}

class _AddApiPageState extends ConsumerState<AddApiPage> {
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _labelController = TextEditingController();
  final _apiKeyFocus = FocusNode();
  final _apiSecretFocus = FocusNode();
  final _passphraseFocus = FocusNode();
  final _labelFocus = FocusNode();
  bool _obscureSecret = true;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _passphraseController.dispose();
    _labelController.dispose();
    _apiKeyFocus.dispose();
    _apiSecretFocus.dispose();
    _passphraseFocus.dispose();
    _labelFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(addApiProvider(widget.exchangeId).notifier);
    final success = await notifier.submitConnection();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exchange connected successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addApiProvider(widget.exchangeId));
    final notifier = ref.read(addApiProvider(widget.exchangeId).notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textOnSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Connect ${state.exchangeName ?? state.exchangeId}',
          style: GoogleFonts.spaceGrotesk(
            color: AppTheme.textOnSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: _parseColor(state.exchangeLogoColor)
                    .withAlpha(51),
                child: Text(
                  state.exchangeLogoLetter,
                  style: TextStyle(
                    color: _parseColor(state.exchangeLogoColor),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Read-only API keys only',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (state.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
color: AppTheme.error.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildTextField(
              label: 'API Key',
              controller: _apiKeyController,
              focusNode: _apiKeyFocus,
              autofocus: true,
              onChanged: notifier.setApiKey,
              hintText: 'Enter your API key',
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _apiSecretFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'API Secret',
              controller: _apiSecretController,
              focusNode: _apiSecretFocus,
              onChanged: notifier.setApiSecret,
              hintText: 'Enter your API secret',
              obscure: _obscureSecret,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => state.requiresPassphrase
                  ? _passphraseFocus.requestFocus()
                  : _labelFocus.requestFocus(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSecret ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _obscureSecret = !_obscureSecret),
              ),
            ),
            if (state.requiresPassphrase) ...[
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Passphrase',
                controller: _passphraseController,
                focusNode: _passphraseFocus,
                onChanged: notifier.setPassphrase,
                hintText: 'Enter your passphrase',
                obscure: true,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _labelFocus.requestFocus(),
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Label (Optional)',
              controller: _labelController,
              focusNode: _labelFocus,
              onChanged: notifier.setLabel,
              hintText: 'e.g. My Trading Account',
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (state.canSubmit) _submit();
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Connect',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withAlpha(13),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.accentCyan.withAlpha(51)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined,
                      color: AppTheme.accentCyan, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your API keys are encrypted with AES-256 and stored securely. We only request read-only permissions.',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? hintText,
    bool obscure = false,
    Widget? suffixIcon,
    FocusNode? focusNode,
    bool autofocus = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textOnSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          obscureText: obscure,
          style: const TextStyle(color: AppTheme.textOnSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.accentCyan),
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null) return AppTheme.accentCyan;
    try {
      final hexClean = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexClean', radix: 16));
    } catch (_) {
      return AppTheme.accentCyan;
    }
  }
}
