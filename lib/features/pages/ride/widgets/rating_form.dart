import 'package:flutter/material.dart';

import 'package:urbanogo/core/theme/app_colors.dart';

class RatingForm extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool submitting;
  final bool submitted;
  final String? errorMessage;
  final void Function(int score, String? comment) onSubmit;
  final VoidCallback onDone;

  const RatingForm({
    super.key,
    required this.title,
    required this.subtitle,
    required this.submitting,
    required this.submitted,
    required this.errorMessage,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  State<RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends State<RatingForm> {
  final TextEditingController _comment = TextEditingController();
  int _score = 0;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _comment.text.trim();
    widget.onSubmit(_score, text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.submitted) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Obrigado pela avaliação!',
            style: TextStyle(
              color: AppColors.cloud,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _filledButton('Nova corrida', widget.onDone),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.cloud,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(widget.subtitle, style: const TextStyle(color: AppColors.mist)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final value = index + 1;
            return IconButton(
              onPressed: widget.submitting
                  ? null
                  : () => setState(() => _score = value),
              icon: Icon(
                value <= _score ? Icons.star : Icons.star_border,
                color: AppColors.sol,
                size: 36,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comment,
          enabled: !widget.submitting,
          maxLines: 2,
          style: const TextStyle(color: AppColors.cloud),
          decoration: InputDecoration(
            hintText: 'Comentário (opcional)',
            hintStyle: const TextStyle(color: AppColors.mist),
            filled: true,
            fillColor: AppColors.ink,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorMessage!,
            style: const TextStyle(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: widget.submitting || _score == 0 ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cloud,
              foregroundColor: AppColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: widget.submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.ink,
                    ),
                  )
                : const Text(
                    'Enviar avaliação',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        TextButton(
          onPressed: widget.submitting ? null : widget.onDone,
          style: TextButton.styleFrom(foregroundColor: AppColors.mist),
          child: const Text('Agora não'),
        ),
      ],
    );
  }

  Widget _filledButton(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cloud,
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
