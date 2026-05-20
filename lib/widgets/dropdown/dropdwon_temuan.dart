import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:safety_apps/widgets/label_text.dart';

class DropdownTemuan extends StatefulWidget {
  final String? value;
  final bool showError;
  final Function(String? selectedValue, String? manualValue) onChanged;

  const DropdownTemuan({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  @override
  State<DropdownTemuan> createState() => _DropdownTemuanState();
}

class _DropdownTemuanState extends State<DropdownTemuan> {
  final TextEditingController _manualController = TextEditingController();

  static const List<String> temuanList = [
    "Kondisi Tidak Aman (KTA)",
    "Tindakan Tidak Aman (TTA)",
    "Lainnya",
  ];

  String? selectedItem;
  bool isOtherSelected = false;

  @override
  void initState() {
    super.initState();
    selectedItem = widget.value;
    isOtherSelected = widget.value == "Lainnya";
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    OutlineInputBorder buildBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabelText("Jenis Temuan", showError: widget.showError),
          const SizedBox(height: 8),
          DropdownSearch<String>(
            items: temuanList,
            selectedItem: selectedItem,
            compareFn: (a, b) => a == b,
            popupProps: PopupProps.menu(
              showSearchBox: true,
              fit: FlexFit.loose,
              constraints: const BoxConstraints(maxHeight: 320),
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Cari data...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: buildBorder(const Color(0xFFE5E7EB)),
                  enabledBorder: buildBorder(const Color(0xFFE5E7EB)),
                  focusedBorder: buildBorder(const Color(0xFF2563EB), 1.2),
                ),
              ),
              menuProps: MenuProps(
                backgroundColor: Colors.white,
                elevation: 8,
                borderRadius: BorderRadius.circular(18),
              ),
              itemBuilder: (context, item, isSelected) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEFF6FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    title: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF111827),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2563EB),
                            size: 18,
                          )
                        : null,
                  ),
                );
              },
              emptyBuilder: (context, searchEntry) => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Data tidak ditemukan',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: "Pilih Temuan",
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF6B7280),
                  size: 22,
                ),
                enabledBorder: buildBorder(const Color(0xFFE5E7EB)),
                focusedBorder: buildBorder(const Color(0xFF2563EB), 1.2),
                border: buildBorder(const Color(0xFFE5E7EB)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                selectedItem = value;
                isOtherSelected = value == "Lainnya";

                if (!isOtherSelected) {
                  _manualController.clear();
                }
              });

              widget.onChanged(
                value,
                value == "Lainnya" ? _manualController.text : null,
              );
            },
          ),
          if (isOtherSelected) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _manualController,
              decoration: InputDecoration(
                labelText: 'Input temuan lainnya',
                labelStyle: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
                hintText: 'Masukkan temuan manual',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: buildBorder(const Color(0xFFE5E7EB)),
                focusedBorder: buildBorder(const Color(0xFF2563EB), 1.2),
                border: buildBorder(const Color(0xFFE5E7EB)),
              ),
              onChanged: (value) {
                widget.onChanged(selectedItem, value);
              },
            ),
          ],
        ],
      ),
    );
  }
}
