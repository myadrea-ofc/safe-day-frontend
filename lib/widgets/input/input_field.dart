import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../field_box.dart';

enum InputType { text, integer }

class InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final InputType inputType;

  final Function(String)? onChanged; // ✅ tambahkan ini
  final bool readOnly;
  final bool enabled;

  const InputField({
    Key? key,
    required this.controller,
    required this.hint,
    this.inputType = InputType.text,
    this.onChanged, // ✅ tambahkan ini
    this.readOnly = false,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: fieldBox(),
      child: TextField(
        controller: controller,
        keyboardType: _keyboardType(),
        inputFormatters: _inputFormatters(),
        onChanged: onChanged, // ✅ pasang di sini
        readOnly: readOnly,
        enabled: enabled,
        decoration: InputDecoration(border: InputBorder.none, hintText: hint),
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
