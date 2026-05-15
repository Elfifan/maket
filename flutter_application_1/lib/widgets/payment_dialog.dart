import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/theme_provider.dart';

class PaymentDialog extends StatefulWidget {
  final double amount;

  const PaymentDialog({super.key, required this.amount});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _processPayment() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isProcessing = true;
      });
      // Имитация обработки платежа
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop(true); // Возвращаем true при успешной оплате
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.textPrimary;
    final borderColor = context.borderColor;

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Оплата курса',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () {
                      if (!_isProcessing) Navigator.of(context).pop(false);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'К оплате: ${widget.amount.toStringAsFixed(0)} ₽',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFFA58EFF), // primaryPurple
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              // Номер карты
              TextFormField(
                controller: _cardNumberController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: 'Номер карты',
                  labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
                  hintText: '0000 0000 0000 0000',
                  hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFA58EFF)),
                  ),
                  prefixIcon: Icon(Icons.credit_card, color: textColor.withValues(alpha: 0.6)),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: (value) =>
                    value == null || value.length < 16 ? 'Введите 16 цифр' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Срок действия
                  Expanded(
                    child: TextFormField(
                      controller: _expiryDateController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Срок (ММ/ГГ)',
                        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
                        hintText: '12/25',
                        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFA58EFF)),
                        ),
                      ),
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: (value) {
                        if (value == null || value.length < 5 || !value.contains('/')) {
                          return 'ММ/ГГ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // CVV
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
                        hintText: '123',
                        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFA58EFF)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: (value) =>
                          value == null || value.length < 3 ? '3 цифры' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: GestureDetector(
                    onTap: _isProcessing ? null : _processPayment,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFA58EFF).withValues(alpha: 0.18),
                            const Color(0xFFF2C9D4).withValues(alpha: 0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Продолжить',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x80000000),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
