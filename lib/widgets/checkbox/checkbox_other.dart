import 'package:flutter/material.dart';

class CheckboxOther extends StatefulWidget {
  final String? selected;
  final Function(String) onChanged;

  final List<String> options;

  const CheckboxOther({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.options,
  });

  @override
  State<CheckboxOther> createState() => _CheckboxOtherState();
}

class _CheckboxOtherState extends State<CheckboxOther> {
  String? selectedLocal;
  TextEditingController otherController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedLocal = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // === OPSI YANG DIKIRIM DARI PAGE ===
        ...widget.options.map((o) {
          return RadioListTile(
            title: Text(o),
            value: o,
            groupValue: selectedLocal,
            onChanged: (v) {
              setState(() {
                selectedLocal = v as String;
              });
              widget.onChanged(v as String);
            },
            activeColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),

        RadioListTile(
          title: const Text("Other"),
          value: "other",
          groupValue: selectedLocal,
          onChanged: (v) {
            setState(() {
              selectedLocal = "other";
            });
            widget.onChanged(otherController.text);
          },
          activeColor: Colors.blueAccent,
        ),

        if (selectedLocal == "other")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: otherController,
              decoration: InputDecoration(
                labelText: "Tulis opsi lainnya",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                widget.onChanged(v);
              },
            ),
          ),
      ],
    );
  }
}
