import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:safety_apps/models/dropdown_item.dart';
import 'package:safety_apps/service/dropdown_service.dart';
import 'package:safety_apps/widgets/label_text.dart';

class SearchableMasterDropdown extends StatefulWidget {
  final String label;
  final String hint;
  final String endpoint;
  final DropdownItemModel? selectedValue;
  final bool showError;
  final Function(DropdownItemModel? selectedItem, String? manualValue)
  onChanged;

  const SearchableMasterDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.endpoint,
    required this.selectedValue,
    required this.onChanged,
    this.showError = false,
  });

  @override
  State<SearchableMasterDropdown> createState() =>
      _SearchableMasterDropdownState();
}

class _SearchableMasterDropdownState extends State<SearchableMasterDropdown> {
  final MasterDataService _service = MasterDataService();
  final TextEditingController _manualController = TextEditingController();

  List<DropdownItemModel> items = [];
  DropdownItemModel? selectedItem;
  bool isLoading = true;
  bool isOtherSelected = false;

  @override
  void initState() {
    super.initState();
    selectedItem = widget.selectedValue;
    isOtherSelected = widget.selectedValue?.isOther == true;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final result = await _service.fetchMasterData(widget.endpoint);

      if (!result.any((e) => e.isOther)) {
        result.add(
          DropdownItemModel(id: null, label: 'Lainnya', isOther: true),
        );
      }

      if (!mounted) return;

      setState(() {
        items = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal load data: $e')));
    }
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
      margin: const EdgeInsets.only(top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabelText(widget.label, showError: widget.showError),
          const SizedBox(height: 8),
          if (isLoading)
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: borderRadius,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            )
          else
            DropdownSearch<DropdownItemModel>(
              items: items,
              selectedItem: selectedItem,
              itemAsString: (item) => item.label,
              compareFn: (a, b) => a.id == b.id && a.label == b.label,

              popupProps: PopupProps.menu(
                showSearchBox: true,
                fit: FlexFit.loose,
                constraints: const BoxConstraints(maxHeight: 320),
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search...',
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
                        item.label,
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
                  hintText: widget.hint,
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
                  isOtherSelected = value?.isOther == true;

                  if (!isOtherSelected) {
                    _manualController.clear();
                  }
                });

                widget.onChanged(
                  value,
                  value?.isOther == true ? _manualController.text : null,
                );
              },
            ),
          if (isOtherSelected) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _manualController,
              decoration: InputDecoration(
                labelText: 'Input ${widget.label} lainnya',
                labelStyle: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
                hintText: 'Masukkan ${widget.label.toLowerCase()} manual',
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
