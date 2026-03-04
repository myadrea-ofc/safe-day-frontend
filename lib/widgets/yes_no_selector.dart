import 'package:flutter/material.dart';

class YesNoSelector extends StatefulWidget {
  final Function(String) onChanged;
  final String? initialValue;

  const YesNoSelector({super.key, required this.onChanged, this.initialValue});

  @override
  State<YesNoSelector> createState() => _YesNoSelectorState();
}

class _YesNoSelectorState extends State<YesNoSelector> {
  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialValue;
  }

  Widget buildButton(String label) {
    bool active = selected == label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selected = label);
          widget.onChanged(label);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active ? Colors.blue : Colors.grey.shade300,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.black87,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [buildButton("Iya"), SizedBox(width: 10), buildButton("Tidak")],
    );
  }
}
