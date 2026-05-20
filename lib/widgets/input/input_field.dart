import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum InputType { text, integer }

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final InputType inputType;
  final Function(String)? onChanged;
  final bool readOnly;
  final bool enabled;

  const InputField({
    Key? key,
    required this.controller,
    required this.hint,
    this.inputType = InputType.text,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    OutlineInputBorder buildBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return TextField(
      controller: controller,
      keyboardType: _keyboardType(),
      inputFormatters: _inputFormatters(),
      onChanged: onChanged,
      readOnly: readOnly,
      enabled: enabled,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF111827),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF9CA3AF),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: buildBorder(const Color(0xFFE5E7EB)),
        focusedBorder: buildBorder(const Color(0xFF2563EB), 1.2),
        disabledBorder: buildBorder(const Color(0xFFE5E7EB)),
        border: buildBorder(const Color(0xFFE5E7EB)),
      ),
    );
  }

  TextInputType _keyboardType() {
    switch (inputType) {
      case InputType.integer:
        return TextInputType.number;
      case InputType.text:
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _inputFormatters() {
    switch (inputType) {
      case InputType.integer:
        return [FilteringTextInputFormatter.digitsOnly];
      case InputType.text:
      default:
        return [];
    }
  }
}
