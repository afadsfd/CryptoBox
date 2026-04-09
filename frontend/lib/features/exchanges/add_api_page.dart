import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme.dart';
import '../../core/exchanges/models/exchange_info.dart';
import '../../core/l10n/app_localizations.dart';
import '../../shared/widgets/sharp_network_image.dart';
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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('exchange_connected')),
          backgroundColor: AppTheme.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          '${l10n.get('connect')} ${state.exchangeName ?? state.exchangeId}',
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
              child: _buildExchangeAvatar(state),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.get('read_only_api'),
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
              label: l10n.get('api_key'),
              controller: _apiKeyController,
              focusNode: _apiKeyFocus,
              autofocus: true,
              onChanged: notifier.setApiKey,
              hintText: l10n.get('enter_api_key'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _apiSecretFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: l10n.get('api_secret'),
              controller: _apiSecretController,
              focusNode: _apiSecretFocus,
              onChanged: notifier.setApiSecret,
              hintText: l10n.get('enter_api_secret'),
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
                label: l10n.get('passphrase'),
                controller: _passphraseController,
                focusNode: _passphraseFocus,
                onChanged: notifier.setPassphrase,
                hintText: l10n.get('enter_passphrase'),
                obscure: true,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _labelFocus.requestFocus(),
              ),
            ],
            const SizedBox(height: 16),
            _buildTextField(
              label: l10n.get('label_optional'),
              controller: _labelController,
              focusNode: _labelFocus,
              onChanged: notifier.setLabel,
              hintText: l10n.get('label_hint'),
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
                        l10n.get('connect'),
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
                      l10n.get('security_notice'),
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

  Widget _buildExchangeAvatar(AddApiState state) {
    final info = ExchangeInfo.findById(state.exchangeId);
    final logoUrl = info?.logoUrl;
    final fallbackColor = _parseColor(state.exchangeLogoColor);

    Widget fallback = CircleAvatar(
      radius: 36,
      backgroundColor: fallbackColor.withAlpha(51),
      child: Text(
        state.exchangeLogoLetter,
        style: TextStyle(
          color: fallbackColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (logoUrl != null && logoUrl.isNotEmpty) {
      return SharpNetworkImage(
        imageUrl: logoUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(36),
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    }

    return fallback;
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
