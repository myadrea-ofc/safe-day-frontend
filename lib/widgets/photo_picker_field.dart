import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoPickerField extends StatefulWidget {
  final String label;
  final Function(String?) onChanged;

  const PhotoPickerField({
    super.key,
    required this.label,
    required this.onChanged,
  });

  @override
  _PhotoPickerFieldState createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<PhotoPickerField> {
  final ImagePicker picker = ImagePicker();
  String? fileName;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: fileName),
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: Icon(Icons.photo),
      ),
      onTap: () async {
        final XFile? photo = await picker.pickImage(
          source: ImageSource.gallery,
        );

        if (photo != null) {
          setState(() => fileName = photo.name);
          widget.onChanged(photo.path);
        }
      },
    );
  }
}
