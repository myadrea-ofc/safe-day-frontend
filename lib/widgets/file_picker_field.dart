import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerField extends StatefulWidget {
  final String label;
  final Function(String?) onChanged;

  const FilePickerField({
    super.key,
    required this.label,
    required this.onChanged,
  });

  @override
  _FilePickerFieldState createState() => _FilePickerFieldState();
}

class _FilePickerFieldState extends State<FilePickerField> {
  String? fileName;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: Icon(Icons.upload_file),
      ),
      controller: TextEditingController(text: fileName),
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles();

        if (result != null) {
          setState(() => fileName = result.files.single.name);
          widget.onChanged(result.files.single.path);
        }
      },
    );
  }
}
